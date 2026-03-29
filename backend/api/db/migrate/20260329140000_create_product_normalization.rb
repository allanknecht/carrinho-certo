class CreateProductNormalization < ActiveRecord::Migration[8.0]
  def change
    create_table :products_canonical do |t|
      t.string :display_name, null: false
      t.string :normalized_key, null: false
      t.timestamps
    end
    add_index :products_canonical, :normalized_key, unique: true

    create_table :product_aliases do |t|
      t.references :product_canonical, null: false, foreign_key: { to_table: :products_canonical }
      t.string :alias_normalized, null: false
      t.string :source, null: false, default: "manual"
      t.timestamps
    end
    add_index :product_aliases, :alias_normalized, unique: true

    add_reference :receipt_items_raw, :product_canonical, foreign_key: { to_table: :products_canonical }
    add_column :receipt_items_raw, :normalization_source, :string
  end
end
