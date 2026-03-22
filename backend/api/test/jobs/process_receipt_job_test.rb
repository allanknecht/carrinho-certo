require "test_helper"

class ProcessReceiptJobTest < ActiveJob::TestCase
  test "skips when receipt is not queued" do
    receipt = receipts(:one)
    receipt.update!(status: "done")

    ProcessReceiptJob.perform_now(receipt.id)

    assert_equal "done", receipt.reload.status
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
