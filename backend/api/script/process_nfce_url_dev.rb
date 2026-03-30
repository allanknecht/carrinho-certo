# frozen_string_literal: true

# Full pipeline against development DB: fetch URL, parse, persist receipt + lines,
# normalize, observed_prices. Usage:
#   bin/rails runner script/process_nfce_url_dev.rb 'https://dfe-portal...QrCodeNFce?p=...'
#
# Requires a user. Set EMAIL=... PASSWORD=... or uses first User (create one if none).
#
# Por padrão desliga a LLM durante este script: com PRODUCT_NORMALIZATION_LLM_ENABLED=true
# e Ollama lento/indisponível, cada item pode parecer “travado” por até OLLAMA_READ_TIMEOUT
# segundos (vários minutos). Para forçar LLM aqui: SMOKE_KEEP_LLM=1

$stdout.sync = true

url = ARGV[0]
abort "usage: bin/rails runner script/process_nfce_url_dev.rb <consultation_url>" if url.blank?

email = ENV.fetch("EMAIL", nil)
password = ENV.fetch("PASSWORD", nil)

user = if email.present? && password.present?
  User.find_by(email: email) || User.create!(email: email, password: password, password_confirmation: password)
else
  User.first || User.create!(
    email: "dev-smoke@example.com",
    password: "password123",
    password_confirmation: "password123"
  )
end

chave = Receipt.chave_from_source_url(url)
if chave.present? && Receipt.exists?(chave_acesso: chave)
  warn "[smoke] Esta chave de acesso já está cadastrada (NFC-e duplicada). Igual ao 409 da API."
  warn "[smoke] chave_acesso=#{chave}"
  exit 1
end

begin
  receipt = user.receipts.create!(source_url: url, status: "queued", chave_acesso: chave.presence)
rescue ActiveRecord::RecordNotUnique
  warn "[smoke] NFC-e duplicada (índice único em chave_acesso)."
  warn "[smoke] chave_acesso=#{chave}" if chave.present?
  exit 1
end
puts "Created receipt id=#{receipt.id}"

prev_adapter = ActiveJob::Base.queue_adapter
llm_was = Rails.application.config.product_normalization_llm.enabled
if ENV["SMOKE_KEEP_LLM"] != "1" && llm_was
  Rails.application.config.product_normalization_llm.enabled = false
  puts "[smoke] LLM desligada só neste run (SMOKE_KEEP_LLM=1 mantém). Sem isso, Ollama pode travar minutos por item."
end

ActiveJob::Base.queue_adapter = :inline
begin
  puts "[smoke] ProcessReceiptJob (baixa SVRS, grava recibo; com :inline já dispara NormalizeReceiptItemsJob em seguida)…"
  ProcessReceiptJob.perform_now(receipt.id)
  receipt.reload
  puts "[smoke] status=#{receipt.status}"
  if receipt.status == "done"
    receipt.reload
    n_obs = ObservedPrice.joins(:receipt_item_raw).where(receipt_items_raw: { receipt_id: receipt.id }).count
    puts "[smoke] linhas=#{receipt.receipt_item_raws.count} observed_prices=#{n_obs}"
    receipt.receipt_item_raws.order(:ordem).each do |line|
      puts "  ord=#{line.ordem} canonical=#{line.product_canonical_id} src=#{line.normalization_source} obs=#{line.observed_price.present?}"
    end
    ids = receipt.receipt_item_raws.where.not(product_canonical_id: nil).distinct.pluck(:product_canonical_id)
    if ids.any?
      puts "[smoke] Endpoint de preços — use estes ids (mudam a cada truncate/import; não reaproveite 3/4 de outro run):"
      ids.each do |pid|
        puts "  bin/rails runner script/product_prices_smoke.rb #{pid}"
      end
      puts "[smoke] Com só esta nota no mercado, preços podem ficar ocultos (≥2 notas na mesma loja). Teste completo: script/verify_prices_pipeline_smoke.rb (gera 2ª nota fictícia)."
    end
  else
    puts "[smoke] erro: #{receipt.processing_error.inspect}"
  end
ensure
  ActiveJob::Base.queue_adapter = prev_adapter
  Rails.application.config.product_normalization_llm.enabled = llm_was
end
