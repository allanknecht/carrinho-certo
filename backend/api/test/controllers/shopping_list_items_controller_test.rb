# frozen_string_literal: true

require "test_helper"

class ShoppingListItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = @user.generate_token_for(:api)
    @list = shopping_lists(:one)
    @item = shopping_list_items(:one)
    @product = products_canonical(:one)
  end

  test "index returns 401 without token" do
    get shopping_list_items_url(@list), headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end

  test "index returns items ordered" do
    get shopping_list_items_url(@list),
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@token}"
      }
    assert_response :success
    items = JSON.parse(response.body)["items"]
    assert_equal [0, 1], items.map { |i| i["ordem"] }
  end

  test "create appends with auto ordem" do
    assert_difference("ShoppingListItem.count", 1) do
      post shopping_list_items_url(@list),
        params: {
          product_canonical_id: @product.id,
          quantidade: 3
        }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{@token}"
        }
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal @product.id, body["product_canonical_id"]
    assert_equal "3.000", body["quantidade"]
    assert_equal 2, body["ordem"]
  end

  test "create returns 422 for invalid product_canonical_id" do
    assert_no_difference("ShoppingListItem.count") do
      post shopping_list_items_url(@list),
        params: {
          product_canonical_id: 999_999_999,
          quantidade: 1
        }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{@token}"
        }
    end
    assert_response :unprocessable_entity
  end

  test "update changes quantidade and label" do
    patch shopping_list_item_url(@list, @item),
      params: { quantidade: 5, label: "Atualizado" }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@token}"
      }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "5.000", body["quantidade"]
    assert_equal "Atualizado", body["label"]
  end

  test "destroy returns 204" do
    assert_difference("ShoppingListItem.count", -1) do
      delete shopping_list_item_url(@list, @item),
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{@token}"
        }
    end
    assert_response :no_content
  end

  test "nested routes 404 for other users list" do
    other_list = shopping_lists(:two)
    get shopping_list_items_url(other_list),
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@token}"
      }
    assert_response :not_found
  end
end
