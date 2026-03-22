require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  test "login returns token for valid credentials" do
    post auth_login_url,
      params: { email: "one@example.com", password: "password" }.to_json,
      headers: { "Content-Type" => "application/json" }
    assert_response :success
    body = JSON.parse(response.body)
    assert body["token"].present?
    assert_equal "one@example.com", body.dig("user", "email")
  end

  test "login returns 401 for invalid password" do
    post auth_login_url,
      params: { email: "one@example.com", password: "wrong" }.to_json,
      headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end
end
