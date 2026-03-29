require "test_helper"

class ReceiptTest < ActiveSupport::TestCase
  test "rejects chave_acesso that is not exactly 44 digits" do
    r = Receipt.new(
      user: users(:one),
      source_url: "https://dfe-portal.example.com/q",
      status: "queued",
      chave_acesso: "123"
    )
    assert_not r.valid?
    assert_includes r.errors[:chave_acesso].join, "44"
  end
end
