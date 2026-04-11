# frozen_string_literal: true

class ShoppingListItem < ApplicationRecord
  belongs_to :shopping_list, inverse_of: :shopping_list_items
  belongs_to :product_canonical, optional: true, inverse_of: :shopping_list_items

  validates :quantidade, numericality: { greater_than: 0 }
  validates :ordem, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :label, length: { maximum: 500 }, allow_blank: true
  validate :product_canonical_must_exist, if: -> { product_canonical_id.present? }

  private

  def product_canonical_must_exist
    return if ProductCanonical.exists?(product_canonical_id)

    errors.add(:product_canonical_id, "is invalid")
  end
end
