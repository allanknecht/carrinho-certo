# Canonical product identity for price aggregation. Rows are created from normalized
# receipt line text until aliases or a future LLM step merge variants.
class ProductCanonical < ApplicationRecord
  self.table_name = "products_canonical"

  has_many :product_aliases, dependent: :destroy, inverse_of: :product_canonical
  has_many :receipt_item_raws, dependent: :nullify, inverse_of: :product_canonical

  validates :display_name, presence: true
  validates :normalized_key, presence: true, uniqueness: true
end
