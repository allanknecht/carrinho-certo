class CreateStores < ActiveRecord::Migration[8.0]
  def change
    create_table :stores do |t|
      t.string :cnpj, null: false
      t.string :nome, null: false
      t.text :endereco
      t.string :cidade
      t.string :uf, limit: 2

      t.timestamps
    end
    add_index :stores, :cnpj, unique: true
  end
end
