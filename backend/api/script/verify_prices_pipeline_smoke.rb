# frozen_string_literal: true

# Importa uma NFC-e (URL), opcionalmente zera o DB, duplica uma 2ª nota no mesmo mercado
# (para liberar preços no endpoint) e imprime ProductPricesSummary por produto.
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

def receipt_count_for_store_product(store_id, product_id)
  return 0 if store_id.blank?

  Receipt.where(store_id: store_id)
    .joins(:receipt_item_raws)
    .where(receipt_item_raws: { product_canonical_id: product_id })
    .distinct
    .count
end

store_id = base.store_id
lines = base.receipt_item_raws.where.not(product_canonical_id: nil).order(:ordem).to_a

if store_id.present? && lines.any?
  sample_pid = lines.first.product_canonical_id
  rc = receipt_count_for_store_product(store_id, sample_pid)

  if rc < 2
    fake_chave = nil
    20.times do
      cand = Array.new(44) { rand(10) }.join
      next if Receipt.exists?(chave_acesso: cand)

      fake_chave = cand
      break
    end
    abort "[smoke] não consegui gerar chave única" if fake_chave.blank?

    r2 = user.receipts.create!(
      source_url: "https://smoke.local/duplicate-#{SecureRandom.hex(8)}",
      status: "done",
      store_id: store_id,
      data_emissao: base.data_emissao || Date.current,
      chave_acesso: fake_chave,
      valor_total: base.valor_total
    )
    mult = BigDecimal("1.02")
    lines.each do |ln|
      vu = if ln.valor_unitario.present? && ln.valor_unitario.positive?
        (ln.valor_unitario * mult).round(4, BigDecimal::ROUND_HALF_UP)
      end
      vt = if ln.valor_total.present? && ln.valor_total.positive?
        (ln.valor_total * mult).round(2, BigDecimal::ROUND_HALF_UP)
      end
      ln2 = r2.receipt_item_raws.create!(
        descricao_bruta: ln.descricao_bruta,
        codigo_estabelecimento: ln.codigo_estabelecimento,
        quantidade: ln.quantidade,
        unidade: ln.unidade,
        valor_unitario: vu,
        valor_total: vt,
        ordem: ln.ordem,
        product_canonical_id: ln.product_canonical_id,
        normalization_source: ln.normalization_source
      )
      Pricing::RecordObservedPrice.call(ln2)
    end
    puts "[smoke] 2ª nota fictícia id=#{r2.id} (mesmo mercado) para liberar prices_disclosed"
  else
    puts "[smoke] já há ≥2 notas nesse mercado para o produto (sample pid=#{sample_pid}), sem duplicar"
  end
end

puts "\n--- GET /products/:id/prices (resumo interno) ---"
lines.map(&:product_canonical_id).uniq.each do |pid|
  summary = Pricing::ProductPricesSummary.call(product_canonical_id: pid)
  puts JSON.pretty_generate(summary.except(:error).as_json)
  puts "---"
end
