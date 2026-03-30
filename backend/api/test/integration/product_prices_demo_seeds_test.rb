# frozen_string_literal: true

require "test_helper"

class ProductPricesDemoSeedsTest < ActionDispatch::IntegrationTest
  # Não carrega fixtures/*.yml (dados só vêm de Seeds::PricingDemo).
  fixtures []

  setup do
    load Rails.root.join("db/seeds/pricing_demo.rb") unless defined?(Seeds::PricingDemo)
    Seeds::PricingDemo.run!(force: true)
    @user = User.find_by!(email: Seeds::PricingDemo::USER_EMAIL)
    @token = @user.generate_token_for(:api)
    @alpha_id = Seeds::PricingDemo.product_alpha_id
    @beta_id = Seeds::PricingDemo.product_beta_id
  end

  test "GET prices for alpha: one-note store hides prices; multi-note stores disclose and recent_prices" do
    get product_prices_path(@alpha_id),
      headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal true, body["prices_disclosed"]
    assert_equal "11.00", body["relevant_price"]["unit_price"]
    assert_equal "latest_among_verified_stores", body["relevant_price"]["basis"]

    by_name = body["stores"].index_by { |s| s["nome"] }

    one = by_name["Mercado Uma Nota (demo)"]
    assert_equal false, one["prices_disclosed"]
    assert_equal 1, one["receipts_distinct_at_store"]
    assert_equal [], one["recent_prices"]

    two = by_name["Mercado Duas Notas (demo)"]
    assert_equal true, two["prices_disclosed"]
    assert_equal 2, two["receipts_distinct_at_store"]
    assert_equal 2, two["recent_prices"].size
    assert_equal "18.00", two["recent_prices"][0]["unit_price"]
    assert_equal "15.00", two["recent_prices"][1]["unit_price"]

    three = by_name["Mercado Três Notas (demo)"]
    assert_equal true, three["prices_disclosed"]
    assert_equal 3, three["receipts_distinct_at_store"]
    assert_equal 3, three["recent_prices"].size
    # Mais recente primeiro (data_emissao mais nova = última nota da série de 3)
    assert_equal "11.00", three["recent_prices"][0]["unit_price"]
    assert_equal "11.50", three["recent_prices"][1]["unit_price"]
    assert_equal "12.00", three["recent_prices"][2]["unit_price"]
  end

  test "GET prices for beta: hidden at one-note store; relevant from two-note store only" do
    get product_prices_path(@beta_id),
      headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal true, body["prices_disclosed"]
    assert_equal "9.00", body["relevant_price"]["unit_price"]

    by_name = body["stores"].index_by { |s| s["nome"] }

    assert_equal false, by_name["Mercado Uma Nota (demo)"]["prices_disclosed"]
    assert_equal [], by_name["Mercado Uma Nota (demo)"]["recent_prices"]

    two = by_name["Mercado Duas Notas (demo)"]
    assert_equal true, two["prices_disclosed"]
    assert_equal 2, two["recent_prices"].size
    assert_equal "9.00", two["recent_prices"][0]["unit_price"]
    assert_equal "7.50", two["recent_prices"][1]["unit_price"]
  end

  test "unknown product returns 404" do
    get product_prices_path(999_999_999),
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :not_found
  end
end
