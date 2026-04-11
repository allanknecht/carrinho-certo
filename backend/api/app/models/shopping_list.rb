# frozen_string_literal: true

class ShoppingList < ApplicationRecord
  belongs_to :user
  has_many :shopping_list_items, -> { order(:ordem, :id) }, dependent: :destroy, inverse_of: :shopping_list

  validates :name, length: { maximum: 255 }
end
