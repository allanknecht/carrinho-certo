# frozen_string_literal: true

module Pricing
  # Ranks stores for a shopping list using the same rules as ProductPricesSummary:
  # rolling 30-day window (from today) and ≥2 distinct receipts per store per product
  # before a unit price is used for that line at that store.
  class ShoppingListStoreTotals
    def self.call(shopping_list: nil, product_lines: nil)
      new(shopping_list: shopping_list, product_lines: product_lines).call
    end

    def initialize(shopping_list: nil, product_lines: nil)
      @shopping_list = shopping_list
      @product_lines = product_lines
    end

    def call
      line_rows = build_line_rows
      start_on = ProductPricesSummary::PRICE_WINDOW_DAYS.days.ago.to_date
      end_on = Date.current

      product_ids = line_rows.filter_map { |r| r[:product_canonical_id] }.uniq
      price_index, store_ids = build_price_index_and_stores(product_ids, start_on, end_on)
      stores_by_id = Store.where(id: store_ids).index_by(&:id)
      lines_total = line_rows.size
      lines_with_product = line_rows.count { |r| r[:product_canonical_id].present? }
      lines_without_product = lines_total - lines_with_product

      stores = store_ids.map do |store_id|
        build_store_row(
          store_id,
          line_rows,
          price_index,
          lines_without_product,
          stores_by_id[store_id]
        )
      end

      stores.sort_by! { |s| [BigDecimal(s[:estimated_total]), s[:store_id]] }

      {
        shopping_list_id: @shopping_list&.id,
        period_days: ProductPricesSummary::PRICE_WINDOW_DAYS,
        window: { from: start_on.iso8601, to: end_on.iso8601 },
        pricing_criteria: {
          min_distinct_receipts_per_store_per_product: ProductPricesSummary::MIN_DISTINCT_RECEIPTS_PER_STORE
        },
        lines: {
          total: lines_total,
          with_product: lines_with_product,
          without_product: lines_without_product
        },
        stores: stores
      }
    end

    private

    def build_line_rows
      if @shopping_list
        @shopping_list.shopping_list_items.order(:ordem, :id).map do |item|
          {
            product_canonical_id: item.product_canonical_id,
            quantidade: item.quantidade.to_d
          }
        end
      elsif @product_lines
        @product_lines.map do |row|
          h = row.respond_to?(:to_unsafe_h) ? row.to_unsafe_h : row.to_h
          h = h.symbolize_keys
          {
            product_canonical_id: h[:product_canonical_id].presence&.to_i,
            quantidade: BigDecimal(h[:quantidade].to_s)
          }
        end
      else
        raise ArgumentError, "shopping_list or product_lines is required"
      end
    end

    # Returns [ { store_id => { product_id => BigDecimal or nil } }, [store_id, ...] ]
    def build_price_index_and_stores(product_ids, start_on, end_on)
      return [{}, []] if product_ids.empty?

      observations = ObservedPrice
        .includes(:store, receipt_item_raw: :receipt)
        .where(product_canonical_id: product_ids)
        .where(observed_on: start_on..end_on)
        .to_a

      by_store_product = observations.group_by { |o| [o.store_id, o.product_canonical_id] }

      index = {}
      store_ids = []

      by_store_product.each do |(store_id, product_id), rows|
        next if store_id.nil?

        store_ids << store_id
        index[store_id] ||= {}
        index[store_id][product_id] = latest_disclosed_unit(rows)
      end

      [index, store_ids.uniq.sort]
    end

    def latest_disclosed_unit(rows)
      return nil unless store_meets_threshold?(rows)

      sorted = rows.sort_by { |o| [o.observed_on, o.updated_at] }.reverse
      latest = sorted.first
      unit_price(latest)
    end

    def store_meets_threshold?(rows)
      rows.map { |o| o.receipt_item_raw.receipt_id }.uniq.size >= ProductPricesSummary::MIN_DISTINCT_RECEIPTS_PER_STORE
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

    def build_store_row(store_id, line_rows, price_index, lines_without_product, store)
      covered = 0
      total = BigDecimal("0")

      line_rows.each do |row|
        pid = row[:product_canonical_id]
        if pid.blank?
          next
        end

        unit = price_index.dig(store_id, pid)
        if unit
          total += unit * row[:quantidade]
          covered += 1
        end
      end

      missing = lines_without_product + (line_rows.count { |r| r[:product_canonical_id].present? } - covered)

      {
        store_id: store_id,
        nome: store&.nome,
        cnpj: store&.cnpj,
        estimated_total: format_decimal(total),
        lines_covered: covered,
        lines_missing_price: missing
      }
    end

    def format_decimal(value)
      format("%.2f", value.to_d)
    end
  end
end
