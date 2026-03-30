# frozen_string_literal: true

class CreateObservedPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :observed_prices do |t|
      t.references :product_canonical, null: false, foreign_key: { to_table: :products_canonical }
      t.references :store, foreign_key: true
      t.references :receipt_item_raw, null: false, foreign_key: { to_table: :receipt_items_raw },
        index: { unique: true }
      t.date :observed_on, null: false
      t.decimal :quantidade, precision: 12, scale: 3
      t.decimal :valor_unitario, precision: 12, scale: 4
      t.decimal :valor_total, precision: 12, scale: 2

      t.timestamps
    end

    add_index :observed_prices, %i[product_canonical_id observed_on],
      name: "index_observed_prices_on_product_canonical_and_observed_on"
  end
end
