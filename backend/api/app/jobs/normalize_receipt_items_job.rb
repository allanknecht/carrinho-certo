# frozen_string_literal: true

# Runs after ProcessReceiptJob commits receipt + raw lines so parsing is durable before LLM/DB work.
class NormalizeReceiptItemsJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(receipt_id)
    receipt = Receipt.find(receipt_id)
    return unless receipt.status == "done"

    n = receipt.receipt_item_raws.count
    Rails.logger.info("[NormalizeReceiptItemsJob] receipt_id=#{receipt_id} normalizing #{n} line(s)…")

    receipt.receipt_item_raws.find_each do |row|
      if row.product_canonical_id.nil?
        ProductNormalization::AssignCanonical.call(row)
        row.reload
      end
      Pricing::RecordObservedPrice.call(row) if row.product_canonical_id.present?
    end

    Rails.logger.info("[NormalizeReceiptItemsJob] receipt_id=#{receipt_id} done.")
  end
end
