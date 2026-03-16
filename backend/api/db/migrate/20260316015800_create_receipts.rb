class CreateReceipts < ActiveRecord::Migration[8.0]
  def change
    create_table :receipts do |t|
      t.text :source_url
      t.string :status

      t.timestamps
    end
  end
end
