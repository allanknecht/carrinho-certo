class CreateReceiptItemsRaw < ActiveRecord::Migration[8.0]
  def change
    create_table :receipt_items_raw do |t|
      t.references :receipt, null: false, foreign_key: true
      t.text :descricao_bruta, null: false
      t.string :codigo_estabelecimento
      t.decimal :quantidade, precision: 12, scale: 3
      t.string :unidade, limit: 10
      t.decimal :valor_unitario, precision: 12, scale: 4
      t.decimal :valor_total, precision: 12, scale: 2
      t.integer :ordem, null: false, default: 0

      t.timestamps
    end
  end
end
