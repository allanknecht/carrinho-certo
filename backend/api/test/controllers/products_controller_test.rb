require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = @user.generate_token_for(:api)
    @headers = { "Authorization" => "Bearer #{@token}" }
  end

  test "returns 401 without token" do
    get products_path
    assert_response :unauthorized
  end

  test "returns empty list when no products match" do
    get products_path, params: { q: "___no_match_xyz___" }, headers: @headers
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [], body["products"]
    assert_equal 0, body["meta"]["total"]
    assert_equal 0, body["meta"]["total_pages"]
  end

  test "lists products ordered by display_name with meta" do
    a = z = nil
    prefix = "ORD#{SecureRandom.hex(4)}"
    z = ProductCanonical.create!(
      normalized_key: "#{prefix} ZKEY",
      display_name: "#{prefix} Zeta"
    )
    a = ProductCanonical.create!(
      normalized_key: "#{prefix} AKEY",
      display_name: "#{prefix} Alpha"
    )

    get products_path, params: { q: prefix }, headers: @headers
    assert_response :success
    body = JSON.parse(response.body)
    names = body["products"].map { |p| p["display_name"] }
    assert_equal ["#{prefix} Alpha", "#{prefix} Zeta"], names
    assert_equal 2, body["products"].size
    assert_equal 1, body["meta"]["page"]
    assert_equal 20, body["meta"]["per"]
    assert_equal 2, body["meta"]["total"]
    assert_equal 1, body["meta"]["total_pages"]
    row = body["products"].find { |p| p["id"] == a.id }
    assert_equal a.display_name, row["display_name"]
    assert_equal a.normalized_key, row["normalized_key"]
  ensure
    [a, z].compact.each(&:destroy)
  end

  test "filters by q on display_name" do
    pc = ProductCanonical.create!(
      normalized_key: "FILTER DN #{SecureRandom.hex(4)}",
      display_name: "Café Pilão 500g"
    )

    get products_path, params: { q: "pilão" }, headers: @headers
    assert_response :success
    body = JSON.parse(response.body)
    ids = body["products"].map { |p| p["id"] }
    assert_includes ids, pc.id
  ensure
    pc&.destroy
  end

  test "filters by q on normalized_key" do
    pc = ProductCanonical.create!(
      normalized_key: "ARROZ TIO JOAO 1KG #{SecureRandom.hex(2)}",
      display_name: "Arroz"
    )

    get products_path, params: { q: "TIO JOAO" }, headers: @headers
    assert_response :success
    body = JSON.parse(response.body)
    ids = body["products"].map { |p| p["id"] }
    assert_includes ids, pc.id
  ensure
    pc&.destroy
  end

  test "paginates with page and per" do
    prefix = "PAG#{SecureRandom.hex(4)}"
    created = 3.times.map do |i|
      ProductCanonical.create!(
        normalized_key: "#{prefix} KEY #{i}",
        display_name: "#{prefix} Name #{i}"
      )
    end

    get products_path, params: { q: prefix, per: 2, page: 1 }, headers: @headers
    body = JSON.parse(response.body)
    assert_equal 2, body["products"].size
    assert_equal 3, body["meta"]["total"]
    assert_equal 2, body["meta"]["per"]
    assert_equal 2, body["meta"]["total_pages"]

    get products_path, params: { q: prefix, per: 2, page: 2 }, headers: @headers
    body = JSON.parse(response.body)
    assert_equal 1, body["products"].size
  ensure
    created&.each(&:destroy)
  end

  test "caps per at maximum" do
    get products_path, params: { per: 500 }, headers: @headers
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 100, body["meta"]["per"]
  end
end
