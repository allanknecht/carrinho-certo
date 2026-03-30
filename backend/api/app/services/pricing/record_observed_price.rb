# frozen_string_literal: true

module Pricing
  # Persists a single price observation from a normalized receipt line (idempotent per line).
  class RecordObservedPrice
    def self.call(receipt_item_raw)
      new(receipt_item_raw).call
    end

    def initialize(row)
      @row = row
    end

    def call
      return if @row.product_canonical_id.blank?
      return if ObservedPrice.exists?(receipt_item_raw_id: @row.id)

      receipt = @row.receipt
      return if receipt.blank?

      observed_on = receipt.data_emissao.presence || receipt.processed_at&.to_date || Time.zone.today

      ObservedPrice.create!(
        product_canonical_id: @row.product_canonical_id,
        store_id: receipt.store_id,
        receipt_item_raw_id: @row.id,
        observed_on: observed_on,
        quantidade: @row.quantidade,
        unidade: @row.unidade.to_s.presence,
        valor_unitario: @row.valor_unitario,
        valor_total: @row.valor_total
      )
    end
  end
end
