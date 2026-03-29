require "test_helper"

class NormalizeReceiptItemsJobTest < ActiveJob::TestCase
  parallelize(workers: 1)

  test "skips when receipt is not done" do
    receipt = receipts(:one)
    receipt.update!(status: "queued")

    NormalizeReceiptItemsJob.perform_now(receipt.id)

    line = receipt.receipt_item_raws.first
    assert line.blank? || line.product_canonical_id.blank?
  end

  test "assigns canonicals for raw lines without canonical" do
    receipt = receipts(:one)
    receipt.update!(status: "done", chave_acesso: "35250814255342000183650060000099991098765432")
    receipt.receipt_item_raws.delete_all
    row = receipt.receipt_item_raws.create!(
      descricao_bruta: "Arroz 5kg",
      quantidade: 1,
      unidade: "UN",
      valor_unitario: 21,
      valor_total: 21,
      ordem: 0
    )

    NormalizeReceiptItemsJob.perform_now(receipt.id)

    row.reload
    assert row.product_canonical_id.present?
    assert_equal "new_canonical", row.normalization_source
  end
end
