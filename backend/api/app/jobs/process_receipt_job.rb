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

      receipt.update_columns(status: "processing", processing_error: nil, updated_at: Time.current)
    end

    receipt.reload
    body = fetch_receipt_page(receipt)
    parsed = NfceConsultationParser.call(body, source_url: receipt.source_url)

    if parsed.chave_acesso.present? &&
        Receipt.where(chave_acesso: parsed.chave_acesso).where.not(id: receipt.id).exists?
      raise "Nota já cadastrada (chave duplicada)."
    end

    store = resolve_store(parsed)

    ApplicationRecord.transaction do
      receipt.receipt_item_raws.delete_all
      receipt.update!(
        store_id: store&.id,
        chave_acesso: parsed.chave_acesso,
        numero: parsed.numero,
        serie: parsed.serie,
        data_emissao: parsed.data_emissao,
        hora_emissao: hora_for_column(parsed.hora_emissao),
        valor_total: parsed.valor_total,
        status: "done",
        processed_at: Time.current,
        processing_error: nil
      )

      parsed.items.each do |item|
        receipt.receipt_item_raws.create!(
          descricao_bruta: item.descricao_bruta,
          codigo_estabelecimento: item.codigo_estabelecimento,
          quantidade: item.quantidade,
          unidade: item.unidade,
          valor_unitario: item.valor_unitario,
          valor_total: item.valor_total,
          ordem: item.ordem
        )
      end
    end
  rescue NfceConsultationParser::ParseError => e
    mark_receipt_failed(receipt, e.message)
  rescue ActiveRecord::RecordNotUnique => e
    msg = e.message.to_s.include?("chave_acesso") ? "Nota já cadastrada (chave duplicada)." : e.message
    mark_receipt_failed(receipt, msg)
  rescue StandardError => e
    mark_receipt_failed(receipt, e.message)
  end

  private

  def mark_receipt_failed(receipt, message)
    return unless receipt

    receipt.update_columns(
      status: "failed",
      processing_error: message.to_s,
      processed_at: Time.current,
      updated_at: Time.current
    )
  end

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

    body
  end

  def resolve_store(parsed)
    cnpj = parsed.store_cnpj.to_s.gsub(/\D/, "")
    return nil if cnpj.length != 14

    Store.find_or_create_by!(cnpj:) do |store|
      store.nome = parsed.store_nome.presence || "Estabelecimento"
      store.endereco = parsed.store_endereco
      store.cidade = parsed.store_cidade
      store.uf = parsed.store_uf.to_s.upcase[0, 2].presence
    end
  end

  def hora_for_column(hora_emissao)
    return nil if hora_emissao.blank?

    Time.zone.parse("2000-01-01 #{hora_emissao}")
  end
end
