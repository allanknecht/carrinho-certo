# frozen_string_literal: true

require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "destroy returns 401 without Authorization" do
    delete account_url
    assert_response :unauthorized
  end

  test "destroy returns 401 with invalid token" do
    delete account_url, headers: { "Authorization" => "Bearer invalid" }
    assert_response :unauthorized
  end

  test "destroy removes user, deletes shopping lists and items, nullifies receipts keeping chave_acesso" do
    user = User.create!(email: "deleter@example.com", password: "password123")
    token = user.generate_token_for(:api)
    chave = "35250814255342000183650060000012341012345679"
    receipt = Receipt.create!(
      user: user,
      source_url: "https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=#{chave}",
      status: "done",
      chave_acesso: chave
    )
    list = ShoppingList.create!(user: user, name: "Minha lista")
    item = ShoppingListItem.create!(shopping_list: list, label: "item", quantidade: 1, ordem: 0)

    assert_difference -> { User.count }, -1 do
      assert_difference -> { ShoppingList.count }, -1 do
        assert_difference -> { ShoppingListItem.count }, -1 do
          assert_no_difference -> { Receipt.count } do
            delete account_url,
              headers: {
                "Content-Type" => "application/json",
                "Authorization" => "Bearer #{token}"
              }
          end
        end
      end
    end

    assert_response :no_content
    assert_nil User.find_by(id: user.id)
    receipt.reload
    assert_nil receipt.user_id
    assert_equal chave, receipt.chave_acesso
    assert_nil ShoppingList.find_by(id: list.id)
    assert_nil ShoppingListItem.find_by(id: item.id)
  end
end
