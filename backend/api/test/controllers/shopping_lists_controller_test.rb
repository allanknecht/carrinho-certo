require "test_helper"

class ShoppingListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = @user.generate_token_for(:api)
    @headers = { "Authorization" => "Bearer #{@token}" }
  end

  test "store_rankings returns 401 without token" do
    list = ShoppingList.create!(user: @user, name: "L")
    get store_rankings_shopping_list_path(list)
    assert_response :unauthorized
  ensure
    list&.destroy
  end

  test "store_rankings returns 404 for other users list" do
    other = users(:two)
    list = ShoppingList.create!(user: other, name: "Outro")
    get store_rankings_shopping_list_path(list), headers: @headers
    assert_response :not_found
  ensure
    list&.destroy
  end

  test "store_rankings returns payload for own list" do
    list = ShoppingList.create!(user: @user, name: "Minha")
    get store_rankings_shopping_list_path(list), headers: @headers
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal list.id, body["shopping_list_id"]
    refute body.key?("period_days")
    refute body.key?("window")
    assert_equal [], body["stores"]
    assert_equal 0, body["lines"]["total"]
  ensure
    list&.destroy
  end
end
