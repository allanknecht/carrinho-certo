# frozen_string_literal: true

class CreateShoppingListsAndItems < ActiveRecord::Migration[8.0]
  def change
    create_table :shopping_lists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false, default: ""
      t.timestamps
    end

    create_table :shopping_list_items do |t|
      t.references :shopping_list, null: false, foreign_key: true
      t.references :product_canonical, null: true, foreign_key: { to_table: :products_canonical }
      t.string :label
      t.decimal :quantidade, precision: 12, scale: 3, null: false, default: 1
      t.integer :ordem, null: false, default: 0
      t.timestamps
    end

    add_index :shopping_list_items, [:shopping_list_id, :ordem]
  end
end
