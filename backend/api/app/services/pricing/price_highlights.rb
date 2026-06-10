# frozen_string_literal: true

module Pricing
  # Cheapest current price per store for products that have observed prices (home screen).
  class PriceHighlights
    def self.call(limit: 3)
      new(limit:).call
    end

    def initialize(limit: 3)
      @limit = limit
    end

    def call
      products = ProductCanonical
        .joins(:observed_prices)
        .distinct
        .order(:display_name)
        .limit(@limit)

      products.filter_map do |product|
        rows = ObservedPrice.latest_rows_per_store_for_product(product.id).includes(:store).to_a
        next if rows.empty?

        cheapest = rows.min_by { |r| r.valor_unitario.to_d }
        store_name = cheapest.store&.nome.presence || "Mercado"

        {
          product_name: product.display_name,
          price_description: "R$ #{format('%.2f', cheapest.valor_unitario)} no #{store_name}"
        }
      end
    end
  end
end
