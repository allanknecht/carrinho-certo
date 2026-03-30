require "test_helper"

class ProductPricesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = @user.generate_token_for(:api)
  end

  test "returns 401 without token" do
    get product_prices_path(1)
    assert_response :unauthorized
  end

  test "returns 404 for unknown product" do
    get product_prices_path(9_999_999),
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :not_found
    body = JSON.parse(response.body)
    assert_equal "Product not found", body["error"]
  end

  test "returns 200 with summary when data exists" do
    store = Store.create!(cnpj: "22222222000192", nome: "Loja B")
    receipt = @user.receipts.create!(
      source_url: "https://example.com/x",
      status: "done",
      store_id: store.id,
      data_emissao: Date.current
    )
    pc = ProductCanonical.create!(normalized_key: "API PROD #{SecureRandom.hex(4)}", display_name: "No API")
    row = receipt.receipt_item_raws.create!(
      descricao_bruta: "X",
      ordem: 0,
      valor_unitario: 5.5,
      valor_total: 5.5,
      quantidade: 1,
      product_canonical_id: pc.id
    )
    ObservedPrice.create!(
      product_canonical_id: pc.id,
      store_id: store.id,
      receipt_item_raw_id: row.id,
      observed_on: Date.current,
      quantidade: 1,
      valor_unitario: 5.5,
      valor_total: 5.5
    )

    get product_prices_path(pc.id),
      headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal pc.id, body["product"]["id"]
    assert_equal "No API", body["product"]["display_name"]
    assert_equal 30, body["period_days"]
    assert_equal false, body["prices_disclosed"]
    assert_nil body["relevant_price"]
    assert_equal 1, body["stores"].size
    assert_equal false, body["stores"].first["prices_disclosed"]
    assert_equal [], body["stores"].first["recent_prices"]
  end
end
