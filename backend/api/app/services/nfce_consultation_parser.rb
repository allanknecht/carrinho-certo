# frozen_string_literal: true

require "nokogiri"
require "cgi"

# Parses NFC-e consultation payloads (NF-e XML or SEFAZ portal HTML).
class NfceConsultationParser
  class ParseError < StandardError; end

  Item = Struct.new(:descricao_bruta, :codigo_estabelecimento, :quantidade, :unidade, :valor_unitario, :valor_total, :ordem, keyword_init: true)

  Result = Struct.new(
    :chave_acesso,
    :numero,
    :serie,
    :data_emissao,
    :hora_emissao,
    :valor_total,
    :store_cnpj,
    :store_nome,
    :store_endereco,
    :store_cidade,
    :store_uf,
    :items,
    keyword_init: true
  )

  def self.call(body, source_url: nil)
    new(body, source_url:).call
  end

  def self.chave_from_source_url(url)
    return nil if url.blank?

    uri = URI.parse(url)
    if uri.query.present?
      raw_p = CGI.parse(uri.query)["p"]&.first
      if raw_p.present?
        candidate = raw_p.split("|", 2).first.to_s.gsub(/\D/, "")
        return candidate if candidate.length == 44
      end
    end
    url.to_s.scan(/\d{44}/).find { |d| d.length == 44 }
  rescue URI::InvalidURIError
    url.to_s.scan(/\d{44}/).first
  end

  def initialize(body, source_url: nil)
    @body = self.class.scrub_http_body_to_utf8(body)
    @source_url = source_url
  end

  # Net::HTTP often returns ASCII-8BIT; literals and /\u/ regexes are UTF-8 — normalize first.
  def self.scrub_http_body_to_utf8(body)
    s = body.to_s
    return s if s.encoding == Encoding::UTF_8 && s.valid_encoding?

    bytes = s.encoding == Encoding::ASCII_8BIT ? s : s.b
    as_utf8 = bytes.dup.force_encoding(Encoding::UTF_8)
    return as_utf8 if as_utf8.valid_encoding?

    bytes.encode(Encoding::UTF_8, Encoding::Windows_1252, invalid: :replace, undef: :replace)
  rescue Encoding::ConverterNotFoundError, Encoding::UndefinedConversionError
    bytes.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "")
  end

  def call
    return parse_as_xml if xml?

    parse_as_html
  end

  private

  def xml?
    b = @body.lstrip.sub(/\A\uFEFF/, "")
    b.start_with?("<?xml", "<nfeProc", "<NFe")
  end

  def parse_as_xml
    doc = Nokogiri::XML(@body)
    doc.remove_namespaces!

    inf = doc.at("infNFe") || doc.at("//infNFe")
    raise ParseError, "XML has no infNFe node" unless inf

    chave = extract_chave_from_inf(inf)
    raise ParseError, "could not extract 44-digit access key from XML" if chave.blank?

    ide = inf.at("ide")
    emit = inf.at("emit")
    total_node = inf.at("total")

    numero = ide&.at("nNF")&.text&.strip
    serie = ide&.at("serie")&.text&.strip
    dh = ide&.at("dhEmi")&.text&.strip
    d_emi = ide&.at("dEmi")&.text&.strip
    h_emi = ide&.at("hEmi")&.text&.strip

    data_emissao, hora_emissao = parse_emission_datetime(dh, d_emi, h_emi)

    v_nf = total_node&.at("ICMSTot")&.at("vNF")&.text ||
           total_node&.at("vNF")&.text
    valor_total = decimal_or_nil(v_nf)

    store_cnpj, store_nome, store_endereco, store_cidade, store_uf = parse_emit(emit)

    items = []
    inf.xpath(".//det").each_with_index do |det, idx|
      prod = det.at("prod")
      next unless prod

      items << Item.new(
        descricao_bruta: prod.at("xProd")&.text&.strip.presence || "Item",
        codigo_estabelecimento: prod.at("cProd")&.text&.strip,
        quantidade: decimal_or_nil(prod.at("qCom")&.text || prod.at("qTrib")&.text),
        unidade: prod.at("uCom")&.text&.strip || prod.at("uTrib")&.text&.strip,
        valor_unitario: decimal_or_nil(prod.at("vUnCom")&.text || prod.at("vUnTrib")&.text),
        valor_total: decimal_or_nil(prod.at("vProd")&.text),
        ordem: idx
      )
    end

    Result.new(
      chave_acesso: chave,
      numero:,
      serie:,
      data_emissao:,
      hora_emissao:,
      valor_total:,
      store_cnpj:,
      store_nome:,
      store_endereco:,
      store_cidade:,
      store_uf:,
      items:
    )
  end

  def extract_chave_from_inf(inf)
    id_attr = inf["Id"].to_s
    if id_attr.start_with?("NFe")
      digits = id_attr.delete("^0-9")
      return digits if digits.length == 44
    end
    ch = inf.at("chave")&.text&.gsub(/\D/, "")
    return ch if ch&.length == 44

    @body.scan(/\d{44}/).find { |d| d.length == 44 }
  end

  def parse_emission_datetime(dh, d_emi, h_emi)
    if dh.present? && (m = dh.match(/\A(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})/))
      return [ Date.iso8601(m[1]), m[2] ]
    end
    if dh.present?
      t = Time.iso8601(dh)
      return [ t.to_date, t.strftime("%H:%M:%S") ]
    end
    if d_emi.present?
      d = Date.parse(d_emi)
      h = h_emi.present? ? Time.parse("2000-01-01 #{h_emi}").strftime("%H:%M:%S") : nil
      return [ d, h ]
    end
    [ nil, nil ]
  rescue ArgumentError, TypeError
    [ nil, nil ]
  end

  def parse_emit(emit)
    return [ nil, nil, nil, nil, nil ] unless emit

    cnpj = emit.at("CNPJ")&.text&.gsub(/\D/, "")
    cnpj = emit.at("CPF")&.text&.gsub(/\D/, "") if cnpj.blank?
    nome = emit.at("xNome")&.text&.strip
    ende = emit.at("enderEmit")
    if ende
      logr = ende.at("xLgr")&.text&.strip
      nro = ende.at("nro")&.text&.strip
      bairro = ende.at("xBairro")&.text&.strip
      endereco = [ logr, nro, bairro ].compact.join(", ").presence
      cidade = ende.at("xMun")&.text&.strip
      uf = ende.at("UF")&.text&.strip
    end
    [ cnpj, nome, endereco, cidade, uf ]
  end

  def parse_as_html
    chave = self.class.chave_from_source_url(@source_url) if @source_url.present?
    chave ||= @body.scan(/\d{44}/).first
    chave ||= @body.match(/(?:\d{4}\s+){10}\d{4}/)&.[](0)&.gsub(/\D/, "")
    raise ParseError, "could not extract access key from HTML" if chave.blank?

    doc = Nokogiri::HTML(@body)
    plain = html_plain(doc)

    items = extract_items_from_html_tables(doc)
    items = extract_items_from_sefaz_qr_portal_rows(doc) if items.empty?

    meta = parse_html_nota_metadata(plain)

    Result.new(
      chave_acesso: chave,
      numero: meta[:numero],
      serie: meta[:serie],
      data_emissao: meta[:data_emissao],
      hora_emissao: meta[:hora_emissao],
      valor_total: meta[:valor_total],
      store_cnpj: extract_cnpj_from_html(doc),
      store_nome: extract_store_nome_from_html(doc),
      store_endereco: nil,
      store_cidade: nil,
      store_uf: nil,
      items:
    )
  end

  def html_plain(doc)
    doc.text.gsub(/\*{2,}/, "").squeeze(" ").strip
  end

  # Common on state portals (e.g. SVRS QrCodeNFce): first column has description + "(Código: N)",
  # second column has "Vl. Total X,XX" — see https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce
  def extract_items_from_sefaz_qr_portal_rows(doc)
    items = []
    ordem = 0

    doc.css("tr").each do |row|
      cells = row.css("td")
      next if cells.size < 2

      left = normalize_html_cell_text(cells[0].text)
      right = normalize_html_cell_text(cells[1].text)
      next unless left.match?(/\(Código:\s*\d+/i) && right.match?(/Vl\.?\s*Total/i)

      desc = left.split(/\(\s*Código:/i).first&.strip
      cod = left[/\(Código:\s*(\d+)\s*\)/i, 1]
      q = left[/Qtde\.:\s*([\d.,]+)/i, 1]
      un, vu = parse_svrs_left_cell_un_and_unit_price(left)
      vt = right[/Vl\.?\s*Total\s*([\d.,]+)/i, 1]

      items << Item.new(
        descricao_bruta: (desc.presence || left)[0, 500],
        codigo_estabelecimento: cod,
        quantidade: br_decimal(q),
        unidade: un&.strip,
        valor_unitario: br_decimal(vu),
        valor_total: br_decimal(vt),
        ordem: ordem
      )
      ordem += 1
    end

    items
  end

  def normalize_html_cell_text(str)
    str.to_s.gsub(/\*{2,}/, "").gsub(/\s+/, " ").strip
  end

  # SVRS often emits "**UN:** KG**Vl. Unit.:**" so "KG" and "Vl." are adjacent (no space).
  # Unit price may be separated from ":" with NBSP (U+00A0), so use [[:space:]] not just \s.
  def parse_svrs_left_cell_un_and_unit_price(left)
    if (m = left.match(/UN:\s*(.+?)Vl\.?\s*Unit\.:[[:space:]]*([\d.,]+)/im))
      return [ m[1].strip, m[2].strip ]
    end

    un = left[/UN:\s*([A-Za-z0-9.\-]+?)(?=\s+Vl\.?\s*Unit\.)/i, 1]
    vu = left[/Vl\.?\s*Unit\.:[[:space:]]*([\d.,]+)/i, 1]
    [ un, vu ]
  end

  def parse_html_nota_metadata(plain)
    h = {}
    if (m = plain.match(/Número:\s*(\d+)\s*Série:\s*(\d+)\s*Emissão:\s*(\d{2}\/\d{2}\/\d{4})\s+(\d{2}:\d{2}:\d{2})/m))
      h[:numero] = m[1]
      h[:serie] = m[2]
      h[:data_emissao] = Date.strptime(m[3], "%d/%m/%Y")
      h[:hora_emissao] = m[4]
    end
    if (m = plain.match(/Valor a pagar R\$:?\s*([\d.,]+)/i))
      h[:valor_total] = br_decimal(m[1])
    end
    h
  rescue ArgumentError
    h
  end

  def extract_cnpj_from_html(doc)
    text = doc.text
    m = text.match(/CNPJ[:\s]*(\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2})/i)
    return m[1].gsub(/\D/, "") if m

    m = text.match(%r{\b(\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2})\b})
    return m[1].gsub(/\D/, "") if m

    text.scan(/\d{14}/).find { |s| s.length == 14 }
  end

  # SVRS QrCodeNFce: trade name appears immediately before "CNPJ: xx.xxx.xxx/xxxx-xx".
  def extract_store_nome_from_html(doc)
    text = doc.text.gsub(/\*{2,}/, "").squeeze(" ").strip
    m = text.match(
      /\b([A-Za-zÀ-ÿ0-9][A-Za-zÀ-ÿ0-9 .,'&\-]{2,180}?)\s+CNPJ\s*[:\s]*\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}/im
    )
    return clean_store_nome_fragment(m[1]) if m

    nil
  end

  def clean_store_nome_fragment(raw)
    s = raw.to_s.strip.gsub(/\s+/, " ")
    s = s.sub(
      /\A(DOCUMENTO\s+AUXILIAR|NFC-?e|NOTA\s+FISCAL|CONSUMIDOR|DE\s+CONSUMIDOR|ELETR[OÔ]NICA)\s+/i,
      ""
    ).strip
    # SVRS: "… CONSUMIDOR ELETRÔNICAMIX COMERCIO …" (no space before trade name)
    s = s.sub(
      /\A(?:.*?\s+)?(?:DA\s+)?NOTA\s+FISCAL\s+DE\s+CONSUMIDOR\s+ELETR[OÔ]NIC[AO]?\s*/i,
      ""
    ).strip
    s.presence
  end

  def extract_items_from_html_tables(doc)
    items = []
    ordem = 0

    doc.css("table").each do |table|
      rows = table.css("tr")
      next if rows.size < 2

      header_cells = rows.first.css("th, td").map { |c| normalize_html_cell_text(c.text).downcase }
      next unless header_cells.any? { |h| h.include?("prod") || h.include?("descri") }

      rows.drop(1).each do |row|
        cells = row.css("td")
        next if cells.size < 2

        texts = cells.map { |c| normalize_html_cell_text(c.text) }
        desc = texts.find { |t| t.length > 3 && !t.match?(/^\d+([.,]\d+)?$/) }
        next if desc.blank?

        nums = texts.map { |t| br_decimal(t) }.compact
        v_total = nums.max_by { |n| n.to_f }
        v_unit = nums.size >= 2 ? nums.min_by { |n| n.to_f } : nil

        items << Item.new(
          descricao_bruta: desc[0, 500],
          codigo_estabelecimento: nil,
          quantidade: nil,
          unidade: nil,
          valor_unitario: v_unit,
          valor_total: v_total,
          ordem: ordem
        )
        ordem += 1
      end
    end

    items
  end

  def br_decimal(str)
    return nil if str.blank?

    s = str.gsub(/[^\d,.-]/, "")
    return nil if s.blank?

    s = s.tr(".", "").sub(",", ".") if s.include?(",")
    BigDecimal(s)
  rescue ArgumentError
    nil
  end

  def decimal_or_nil(str)
    return nil if str.blank?

    BigDecimal(str.gsub(",", "."))
  rescue ArgumentError
    nil
  end
end
