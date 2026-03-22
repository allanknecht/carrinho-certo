require "test_helper"

class ProcessReceiptJobTest < ActiveJob::TestCase
  # Avoid parallel threads mutating the same `receipts(:one)` fixture.
  parallelize(workers: 1)
  test "skips when receipt is not queued" do
    receipt = receipts(:one)
    receipt.update!(status: "done")

    ProcessReceiptJob.perform_now(receipt.id)

    assert_equal "done", receipt.reload.status
  end

  test "persists parsed XML, store and raw items when fetch succeeds" do
    receipt = receipts(:one)
    receipt.update!(status: "queued", source_url: "https://example.com/nfe")
    xml = file_fixture("nfce_sample.xml").read

    job = ProcessReceiptJob.new
    job.define_singleton_method(:fetch_receipt_page) { |_| xml }
    job.perform(receipt.id)

    receipt.reload
    assert_equal "done", receipt.status
    assert_equal "35250814255342000183650060000099991098765432", receipt.chave_acesso
    assert receipt.store_id.present?
    assert_equal "14255342000183", receipt.store.cnpj
    assert_equal 1, receipt.receipt_item_raws.count
    assert_equal "Arroz 5kg", receipt.receipt_item_raws.first.descricao_bruta
  end

  test "marks failed when fetch raises" do
    receipt = receipts(:one)
    receipt.update!(status: "queued")
    receipt.update_column(:source_url, "ftp://invalid.example")

    ProcessReceiptJob.perform_now(receipt.id)

    receipt.reload
    assert_equal "failed", receipt.status
    assert_match(/http|https|only/i, receipt.processing_error.to_s)
  end
end
