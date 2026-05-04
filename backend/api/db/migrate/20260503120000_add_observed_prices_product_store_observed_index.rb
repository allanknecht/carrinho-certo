# frozen_string_literal: true

class AddObservedPricesProductStoreObservedIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :observed_prices,
      %i[product_canonical_id store_id observed_on updated_at],
      name: "index_observed_prices_on_product_store_observed_at"
  end
end
