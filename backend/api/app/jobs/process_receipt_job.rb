require "net/http"

class ProcessReceiptJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(receipt_id)
    receipt = Receipt.find(receipt_id)
    return unless receipt.status == "queued"

    receipt.with_lock do
      receipt.reload
      return unless receipt.status == "queued"

      receipt.update!(status: "processing", processing_error: nil)
    end

    receipt.reload
    fetch_receipt_page(receipt)
    receipt.update!(status: "done", processed_at: Time.current, processing_error: nil)
  rescue StandardError => e
    receipt&.update(status: "failed", processing_error: e.message, processed_at: Time.current)
  end

  private

  def fetch_receipt_page(receipt)
    uri = URI.parse(receipt.source_url)
    raise ArgumentError, "only http/https URLs are supported" unless uri.is_a?(URI::HTTP)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 20

    path = uri.request_uri
    path = "/" if path.blank?
    request = Net::HTTP::Get.new(path)
    request["User-Agent"] = "CarrinhoCerto/1.0"

    response = http.request(request)
    code = response.code.to_i
    raise "HTTP #{response.code}" unless code.between?(200, 299)

    body = response.body.to_s
    raise "empty response body" if body.blank?

    # Parser NFC-e / itens vem depois; por ora só validamos resposta HTTP com corpo.
    nil
  end
end
