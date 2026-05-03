# frozen_string_literal: true

module Pricing
  # Builds the JSON payload for GET /products/:id/prices from observed_prices rows.
  # Per store: the single latest observation by receipt emission date (observed_on), then updated_at.
  class ProductPricesSummary
    def self.call(product_canonical_id:)
      new(product_canonical_id:).call
    end

    def initialize(product_canonical_id:)
      @product_id = product_canonical_id
    end

    def call
      product = ProductCanonical.find_by(id: @product_id)
      return { error: :not_found } unless product

      rows = ObservedPrice.latest_rows_per_store_for_product(@product_id).includes(:store, receipt_item_raw: :receipt).to_a
      rows.sort_by! { |o| [o.observed_on, o.updated_at] }.reverse

      {
        product: product_payload(product),
        stores: rows.map { |op| build_store_entry(op) }
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

    def build_store_entry(op)
      store = op.store
      pt = price_point(op)
      {
        store_id: op.store_id,
        nome: store&.nome,
        cnpj: store&.cnpj,
        observed_on: op.observed_on.iso8601
      }.merge(pt)
    end

    def price_point(op)
      unit = unit_price(op)
      {
        unit_price: unit ? format_decimal(unit) : nil,
        unidade: line_unidade(op),
        quantidade: format_quantity(op.quantidade),
        line_total: op.valor_total.present? ? format_decimal(op.valor_total) : nil,
        receipt_total: receipt_total_for(op)
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
