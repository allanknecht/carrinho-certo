# frozen_string_literal: true

# Runs after ProcessReceiptJob commits receipt + raw lines so parsing is durable before LLM/DB work.
class NormalizeReceiptItemsJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(receipt_id)
    receipt = Receipt.find(receipt_id)
    return unless receipt.status == "done"

    receipt.receipt_item_raws.where(product_canonical_id: nil).find_each do |row|
      ProductNormalization::AssignCanonical.call(row)
    end
  end
end
