# frozen_string_literal: true

module Pricing
  # Builds the JSON payload for GET /products/:id/prices from observed_prices rows.
  class ProductPricesSummary
    # Only observations with observed_on in this rolling window (from today) are considered.
    PRICE_WINDOW_DAYS = 30
    # Per store: need ≥2 distinct receipts in the window before showing prices (avoids lone discount).
    MIN_DISTINCT_RECEIPTS_PER_STORE = 2
    # Most recent + two older price points per disclosed store.
    RECENT_PRICES_PER_STORE = 3

    def self.call(product_canonical_id:)
      new(product_canonical_id:).call
    end

    def initialize(product_canonical_id:)
      @product_id = product_canonical_id
    end

    def call
      product = ProductCanonical.find_by(id: @product_id)
      return { error: :not_found } unless product

      start_on = PRICE_WINDOW_DAYS.days.ago.to_date
      end_on = Date.current

      observations = ObservedPrice
        .includes(:store, receipt_item_raw: :receipt)
        .where(product_canonical_id: @product_id)
        .where(observed_on: start_on..end_on)
        .order(observed_on: :desc, updated_at: :desc)
        .to_a

      receipt_ids = observations.map { |o| o.receipt_item_raw.receipt_id }.uniq
      receipt_count = receipt_ids.size

      by_store = observations.group_by(&:store_id)
      stores = by_store.map { |store_id, rows| build_store_entry(store_id, rows) }
      stores.sort_by! { |s| s[:last_observed_on] }.reverse

      any_store_disclosed = stores.any? { |s| s[:prices_disclosed] }

      {
        product: product_payload(product),
        period_days: PRICE_WINDOW_DAYS,
        window: { from: start_on.iso8601, to: end_on.iso8601 },
        observations_count: observations.size,
        receipts_distinct_count: receipt_count,
        prices_disclosed: any_store_disclosed,
        relevant_price: build_relevant_global(by_store),
        stores: stores
      }
    end

    private

    def product_payload(product)
      {
        id: product.id,
        display_name: product.display_name,
        normalized_key: product.normalized_key
      }
    end

    def store_meets_threshold?(rows)
      rows.map { |o| o.receipt_item_raw.receipt_id }.uniq.size >= MIN_DISTINCT_RECEIPTS_PER_STORE
    end

    def build_store_entry(store_id, rows)
      sorted = rows.sort_by { |o| [o.observed_on, o.updated_at] }.reverse
      latest = sorted.first
      store = latest.store
      disclosed = store_meets_threshold?(rows)
      receipts_at_store = rows.map { |o| o.receipt_item_raw.receipt_id }.uniq.size

      recent_prices = if disclosed
        sorted.first(RECENT_PRICES_PER_STORE).map { |o| observation_point(o) }
      else
        []
      end

      {
        store_id: store_id,
        nome: store&.nome,
        cnpj: store&.cnpj,
        observations_count: rows.size,
        receipts_distinct_at_store: receipts_at_store,
        prices_disclosed: disclosed,
        last_observed_on: latest.observed_on.iso8601,
        recent_prices: recent_prices
      }
    end

    def build_relevant_global(by_store)
      qualifying = by_store.flat_map { |_sid, rows| store_meets_threshold?(rows) ? rows : [] }
      return nil if qualifying.empty?

      pick = qualifying.max_by { |o| [o.observed_on, o.updated_at] }
      unit = unit_price(pick)
      return nil if unit.nil? && pick.valor_total.blank?

      {
        unit_price: unit ? format_decimal(unit) : nil,
        unidade: line_unidade(pick),
        quantidade: format_quantity(pick.quantidade),
        line_total: pick.valor_total.present? ? format_decimal(pick.valor_total) : nil,
        receipt_total: receipt_total_for(pick),
        observed_on: pick.observed_on.iso8601,
        store_id: pick.store_id,
        basis: "latest_among_verified_stores"
      }
    end

    def observation_point(op)
      unit = unit_price(op)
      {
        unit_price: unit ? format_decimal(unit) : nil,
        unidade: line_unidade(op),
        quantidade: format_quantity(op.quantidade),
        line_total: op.valor_total.present? ? format_decimal(op.valor_total) : nil,
        receipt_total: receipt_total_for(op),
        observed_on: op.observed_on.iso8601
      }
    end

    def unit_price(op)
      if op.valor_unitario.present? && op.valor_unitario.positive?
        return op.valor_unitario
      end
      if op.quantidade.present? && op.quantidade.positive? && op.valor_total.present?
        return op.valor_total / op.quantidade
      end

      op.valor_total if op.valor_total.present?
    end

    def format_decimal(value)
      format("%.2f", value.to_d)
    end

    def format_quantity(q)
      return nil if q.blank?

      s = format("%.3f", q.to_d)
      s.sub(/\.?0+\z/, "")
    end

    def line_unidade(op)
      op.unidade.presence || op.receipt_item_raw&.unidade
    end

    def receipt_total_for(op)
      r = op.receipt_item_raw&.receipt
      return nil if r.nil? || r.valor_total.blank?

      format_decimal(r.valor_total)
    end
  end
end
