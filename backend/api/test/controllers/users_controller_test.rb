require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "create user returns 201" do
    assert_difference("User.count", 1) do
      post users_url,
        params: { email: "new@example.com", password: "secret123" }.to_json,
        headers: { "Content-Type" => "application/json" }
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "new@example.com", body["email"]
  end

  test "create user returns 422 for duplicate email" do
    assert_no_difference("User.count") do
      post users_url,
        params: { email: "one@example.com", password: "secret123" }.to_json,
        headers: { "Content-Type" => "application/json" }
    end
    assert_response :unprocessable_entity
  end
end
