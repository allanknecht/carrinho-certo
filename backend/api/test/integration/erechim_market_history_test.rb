# frozen_string_literal: true

require "test_helper"

class ErechimMarketHistoryTest < ActionDispatch::IntegrationTest
  fixtures []

  setup do
    load Rails.root.join("db/seeds/erechim_market_history.rb") unless defined?(Seeds::ErechimMarketHistory)
    @user = User.find_or_create_by!(email: "erechim-test@local.dev") do |u|
      u.password = "password123"
      u.password_confirmation = "password123"
    end
    Seeds::ErechimMarketHistory.run!(force: true)
    @token = @user.generate_token_for(:api)
    @products = Seeds::ErechimMarketHistory::PRODUCTS.map do |meta|
      ProductCanonical.find_by!(normalized_key: meta[:key])
    end
    @list = @user.shopping_lists.find_by!(name: Seeds::ErechimMarketHistory::LIST_NAME)
  end

  test "each product has current price in all 3 Erechim stores" do
    store_names = Seeds::ErechimMarketHistory::STORES.map { |s| s[:nome] }

    @products.each do |product|
      get product_prices_path(product.id), headers: { "Authorization" => "Bearer #{@token}" }
      assert_response :success

      body = JSON.parse(response.body)
      names = body["stores"].map { |s| s["nome"] }
      store_names.each { |nome| assert_includes names, nome }
      assert_equal 3, body["stores"].size
    end
  end

  test "store rankings on comparison list prefers Koch Erechim" do
    get store_rankings_shopping_list_path(@list), headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :success

    body = JSON.parse(response.body)
    full = body["stores"].select { |s| s["lines_missing_price"].zero? }
    assert_equal 3, full.size

    totals = full.index_by { |s| s["nome"] }
    koch = BigDecimal(totals["Koch Hipermercado Erechim"]["estimated_total"])
    assert koch < BigDecimal(totals["Brizolla Supermercados"]["estimated_total"])
    assert_equal "76.46", totals["Koch Hipermercado Erechim"]["estimated_total"]
  end

  test "all seeded stores are in Erechim" do
    Seeds::ErechimMarketHistory::STORES.each do |meta|
      store = Store.find_by!(cnpj: meta[:cnpj])
      assert_equal "Erechim", store.cidade
      assert_equal "RS", store.uf
    end
  end
end
