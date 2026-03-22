class AddNfFieldsToReceipts < ActiveRecord::Migration[8.0]
  def change
    add_reference :receipts, :store, foreign_key: true, null: true
    add_column :receipts, :chave_acesso, :string, limit: 44
    add_column :receipts, :numero, :string
    add_column :receipts, :serie, :string
    add_column :receipts, :data_emissao, :date
    add_column :receipts, :hora_emissao, :time
    add_column :receipts, :valor_total, :decimal, precision: 12, scale: 2

    add_index :receipts, :chave_acesso, unique: true, where: "chave_acesso IS NOT NULL",
      name: "index_receipts_on_chave_acesso_unique_non_null"
  end
end
