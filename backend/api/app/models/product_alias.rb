# Maps a normalized raw label to a canonical product (e.g. several PDV strings → one SKU).
# `source`: manual, rule, llm, llm_merge (llm_merge = variant/typo linked to existing canonical).
class ProductAlias < ApplicationRecord
  belongs_to :product_canonical, inverse_of: :product_aliases

  validates :alias_normalized, presence: true, uniqueness: true
  validates :source, presence: true
end
