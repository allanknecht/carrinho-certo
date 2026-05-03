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

  test "GET prices for alpha: latest per store by emission date" do
    get product_prices_path(@alpha_id),
      headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :success
    body = JSON.parse(response.body)

    refute body.key?("relevant_price")
    refute body.key?("price_outlier")

    by_name = body["stores"].index_by { |s| s["nome"] }

    one = by_name["Mercado Uma Nota (demo)"]
    assert_equal "10.00", one["unit_price"]
    assert one["observed_on"].present?

    two = by_name["Mercado Duas Notas (demo)"]
    assert_equal "18.00", two["unit_price"]

    three = by_name["Mercado Três Notas (demo)"]
    assert_equal "11.00", three["unit_price"]
  end

  test "GET prices for beta: one-note store still shows price" do
    get product_prices_path(@beta_id),
      headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :success
    body = JSON.parse(response.body)

    refute body.key?("relevant_price")

    by_name = body["stores"].index_by { |s| s["nome"] }

    assert_equal "8.00", by_name["Mercado Uma Nota (demo)"]["unit_price"]

    two = by_name["Mercado Duas Notas (demo)"]
    assert_equal "9.00", two["unit_price"]
  end

  test "unknown product returns 404" do
    get product_prices_path(999_999_999),
      headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :not_found
  end
end
