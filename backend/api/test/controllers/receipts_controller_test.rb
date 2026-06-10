require "test_helper"

class ReceiptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = @user.generate_token_for(:api)
  end

  test "create returns 401 without Authorization" do
    post receipts_url,
      params: { source_url: "https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=test" }.to_json,
      headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end

  test "create returns 401 with invalid token" do
    post receipts_url,
      params: { source_url: "https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=test" }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer invalid"
      }
    assert_response :unauthorized
  end

  test "create returns 202 with flat JSON and Bearer token" do
    assert_difference("Receipt.count", 1) do
      assert_enqueued_jobs 1, only: ProcessReceiptJob do
        post receipts_url,
          params: { source_url: "https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=newnote" }.to_json,
          headers: {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{@token}"
          }
      end
    end
    assert_response :accepted
    body = JSON.parse(response.body)
    assert_equal "queued", body["status"]
    assert body["id"].present?
    assert_equal @user.id, Receipt.order(:id).last.user_id
  end

  test "create persists chave_acesso when URL carries the access key" do
    chave = "43260352932793000180650040000458781305092704"
    url = "https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=#{chave}|2|1|1|HASH"
    assert_difference("Receipt.count", 1) do
      post receipts_url,
        params: { source_url: url }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{@token}"
        }
    end
    assert_response :accepted
    assert_equal chave, Receipt.order(:id).last.chave_acesso
  end

  test "create returns 409 when chave from URL already exists" do
    chave = receipts(:with_chave).chave_acesso
    url = "https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=#{chave}|2|1|1|"
    assert_no_difference("Receipt.count") do
      post receipts_url,
        params: { source_url: url }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{@token}"
        }
    end
    assert_response :conflict
    body = JSON.parse(response.body)
    assert_equal "Receipt already registered", body["error"]
    assert_equal chave, body["chave_acesso"]
  end

  test "create requeues failed receipt with same chave instead of 409" do
    chave = "43260352932793000180650040000458781305092705"
    failed = Receipt.create!(
      user: @user,
      source_url: "https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=#{chave}",
      status: "failed",
      chave_acesso: chave,
      processing_error: "SSL_connect failed"
    )
    url = "https://www.sefaz.rs.gov.br/NFCE/NFCE-COM.aspx?p=#{chave}|3|1"

    assert_no_difference("Receipt.count") do
      assert_enqueued_with(job: ProcessReceiptJob, args: [failed.id]) do
        post receipts_url,
          params: { source_url: url }.to_json,
          headers: {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{@token}"
          }
      end
    end

    assert_response :accepted
    body = JSON.parse(response.body)
    assert_equal failed.id, body["id"]
    assert_equal "queued", body["status"]
    failed.reload
    assert_equal "queued", failed.status
    assert_nil failed.processing_error
    assert_equal url, failed.source_url
  end

  test "create returns 400 for invalid URL" do
    post receipts_url,
      params: { source_url: "not-a-url" }.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@token}"
      }
    assert_response :bad_request
  end
end
