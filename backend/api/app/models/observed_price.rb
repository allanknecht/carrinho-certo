# frozen_string_literal: true

# One row per receipt line with a resolved canonical product: paid values and context
# for aggregation (no user-facing receipt API; internal link via receipt_item_raw only).
class ObservedPrice < ApplicationRecord
  belongs_to :product_canonical, inverse_of: :observed_prices
  belongs_to :store, optional: true, inverse_of: :observed_prices
  belongs_to :receipt_item_raw, inverse_of: :observed_price

  class << self
    # Latest row per store for one product (PostgreSQL DISTINCT ON).
    def latest_rows_per_store_for_product(product_canonical_id)
      select("DISTINCT ON (#{table_name}.store_id) #{table_name}.*")
        .where(product_canonical_id: product_canonical_id)
        .where.not(store_id: nil)
        .order(Arel.sql("#{table_name}.store_id, #{table_name}.observed_on DESC, #{table_name}.updated_at DESC"))
    end

    # Latest row per (store, product) for many products in one query.
    def latest_rows_per_store_for_products(product_ids)
      product_ids = product_ids.uniq.compact
      return none if product_ids.empty?

      select("DISTINCT ON (#{table_name}.store_id, #{table_name}.product_canonical_id) #{table_name}.*")
        .where(product_canonical_id: product_ids)
        .where.not(store_id: nil)
        .order(Arel.sql("#{table_name}.store_id, #{table_name}.product_canonical_id, #{table_name}.observed_on DESC, #{table_name}.updated_at DESC"))
    end
  end
end
