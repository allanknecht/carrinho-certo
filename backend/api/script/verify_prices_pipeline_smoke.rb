# frozen_string_literal: true

# Importa uma NFC-e (URL), opcionalmente zera o DB, imprime ProductPricesSummary por produto.
#
#   SMOKE_TRUNCATE=1 bin/rails runner script/verify_prices_pipeline_smoke.rb
#   SMOKE_TRUNCATE=1 bin/rails runner script/verify_prices_pipeline_smoke.rb 'https://...QrCodeNFce?p=...'
#
# SMOKE_KEEP_LLM=1 mantém LLM ligada (default no script: desliga como process_nfce_url_dev).

DEFAULT_URL = "https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=43260326266835000181650010001963151359350339|2|1|1|97CD54B70E1CD9CC89893ECB8303325C37656308"

$stdout.sync = true

url = ARGV[0].presence || DEFAULT_URL

if ENV["SMOKE_TRUNCATE"] == "1"
  require "rake"
  Rails.application.load_tasks
  Rake::Task["db:truncate_all"].invoke
  puts "[smoke] db truncated"
end

user = User.first || User.create!(
  email: "dev-smoke@example.com",
  password: "password123",
  password_confirmation: "password123"
)

chave = Receipt.chave_from_source_url(url)
base = chave.present? ? Receipt.find_by(chave_acesso: chave) : nil

if base.nil?
  receipt = user.receipts.create!(source_url: url, status: "queued", chave_acesso: chave.presence)
  prev_adapter = ActiveJob::Base.queue_adapter
  llm_was = Rails.application.config.product_normalization_llm.enabled
  if ENV["SMOKE_KEEP_LLM"] != "1" && llm_was
    Rails.application.config.product_normalization_llm.enabled = false
    puts "[smoke] LLM desligada neste run (SMOKE_KEEP_LLM=1 mantém)."
  end
  ActiveJob::Base.queue_adapter = :inline
  ProcessReceiptJob.perform_now(receipt.id)
  ActiveJob::Base.queue_adapter = prev_adapter
  Rails.application.config.product_normalization_llm.enabled = llm_was
  base = receipt.reload
  puts "[smoke] import receipt id=#{base.id} status=#{base.status}"
else
  puts "[smoke] receipt já existe id=#{base.id}, pulando download/import"
end

if base.status != "done"
  warn "[smoke] falha: #{base.processing_error.inspect}"
  exit 1
end

store = base.store
puts "[smoke] store id=#{store&.id} nome=#{store&.nome.inspect} cnpj=#{store&.cnpj}"

lines = base.receipt_item_raws.where.not(product_canonical_id: nil).order(:ordem).to_a

puts "\n--- ProductPricesSummary por produto ---"
lines.map(&:product_canonical_id).uniq.each do |pid|
  summary = Pricing::ProductPricesSummary.call(product_canonical_id: pid)
  puts JSON.pretty_generate(summary.except(:error).as_json)
  puts "---"
end
