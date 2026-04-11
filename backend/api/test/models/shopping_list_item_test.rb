# frozen_string_literal: true

require "test_helper"

class ShoppingListItemTest < ActiveSupport::TestCase
  test "rejects invalid product_canonical_id" do
    list = shopping_lists(:one)
    item = list.shopping_list_items.build(product_canonical_id: 999_999_999, quantidade: 1, ordem: 0)
    assert_not item.valid?
    assert item.errors[:product_canonical_id].present?
  end
end
