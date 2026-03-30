# frozen_string_literal: true

# One row per receipt line with a resolved canonical product: paid values and context
# for aggregation (no user-facing receipt API; internal link via receipt_item_raw only).
class ObservedPrice < ApplicationRecord
  belongs_to :product_canonical, inverse_of: :observed_prices
  belongs_to :store, optional: true, inverse_of: :observed_prices
  belongs_to :receipt_item_raw, inverse_of: :observed_price
end
