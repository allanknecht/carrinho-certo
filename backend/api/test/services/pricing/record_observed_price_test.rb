require "test_helper"

module Pricing
  class RecordObservedPriceTest < ActiveSupport::TestCase
    test "creates observation from normalized line" do
      store = Store.create!(cnpj: "12345678000199", nome: "Loja teste")
      receipt = receipts(:one)
      receipt.update!(
        status: "done",
        store_id: store.id,
        data_emissao: Date.new(2025, 8, 25),
        processed_at: Time.zone.parse("2025-08-25 12:00")
      )
      receipt.receipt_item_raws.delete_all
      pc = ProductCanonical.create!(normalized_key: "TEST SKU", display_name: "Test")
      row = receipt.receipt_item_raws.create!(
        descricao_bruta: "Test",
        quantidade: 2,
        unidade: "KG",
        valor_unitario: 10.5,
        valor_total: 21,
        ordem: 0,
        product_canonical_id: pc.id
      )

      assert_difference("ObservedPrice.count", 1) do
        RecordObservedPrice.call(row)
      end

      op = ObservedPrice.find_by!(receipt_item_raw_id: row.id)
      assert_equal pc.id, op.product_canonical_id
      assert_equal store.id, op.store_id
      assert_equal Date.new(2025, 8, 25), op.observed_on
      assert_equal 2, op.quantidade
      assert_equal 10.5, op.valor_unitario.to_f
      assert_equal 21, op.valor_total.to_f
      assert_equal "KG", op.unidade
    end

    test "is idempotent per receipt line" do
      receipt = receipts(:one)
      receipt.update!(status: "done", data_emissao: Date.current)
      receipt.receipt_item_raws.delete_all
      pc = ProductCanonical.create!(normalized_key: "X", display_name: "X")
      row = receipt.receipt_item_raws.create!(
        descricao_bruta: "X",
        ordem: 0,
        product_canonical_id: pc.id
      )

      RecordObservedPrice.call(row)
      assert_no_difference("ObservedPrice.count") do
        RecordObservedPrice.call(row)
      end
    end

    test "skips when line has no canonical" do
      receipt = receipts(:one)
      receipt.update!(status: "done")
      receipt.receipt_item_raws.delete_all
      row = receipt.receipt_item_raws.create!(descricao_bruta: "Y", ordem: 0)

      assert_no_difference("ObservedPrice.count") do
        RecordObservedPrice.call(row)
      end
    end

    test "uses processed_at date when data_emissao is blank" do
      receipt = receipts(:one)
      receipt.update!(
        status: "done",
        data_emissao: nil,
        processed_at: Time.zone.parse("2026-01-15 10:00")
      )
      receipt.receipt_item_raws.delete_all
      pc = ProductCanonical.create!(normalized_key: "Z", display_name: "Z")
      row = receipt.receipt_item_raws.create!(
        descricao_bruta: "Z",
        ordem: 0,
        product_canonical_id: pc.id
      )

      RecordObservedPrice.call(row)
      assert_equal Date.new(2026, 1, 15), ObservedPrice.last.observed_on
    end
  end
end
