require "test_helper"

class ReceiptsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get receipts_create_url
    assert_response :success
  end
end
