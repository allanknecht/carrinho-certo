class AddUserToReceipts < ActiveRecord::Migration[8.0]
  def up
    add_reference :receipts, :user, null: true, foreign_key: true

    if Receipt.where(user_id: nil).exists?
      user = User.order(:id).first || User.create!(
        email: "legacy-receipts@carrinho-certo.local",
        password: SecureRandom.hex(24)
      )
      Receipt.where(user_id: nil).update_all(user_id: user.id)
    end

    change_column_null :receipts, :user_id, false
  end

  def down
    remove_reference :receipts, :user, foreign_key: true
  end
end
