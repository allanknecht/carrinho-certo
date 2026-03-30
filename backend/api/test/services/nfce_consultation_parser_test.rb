require "test_helper"

class NfceConsultationParserTest < ActiveSupport::TestCase
  test "parses XML NF-e and extracts chave, ide, emit, items" do
    xml = file_fixture("nfce_sample.xml").read
    result = NfceConsultationParser.call(xml)

    assert_equal "35250814255342000183650060000099991098765432", result.chave_acesso
    assert_equal "1234", result.numero
    assert_equal "6", result.serie
    assert_equal Date.new(2025, 8, 25), result.data_emissao
    assert_equal "14:30:00", result.hora_emissao
    assert_equal BigDecimal("21.00"), result.valor_total
    assert_equal "14255342000183", result.store_cnpj
    assert_equal "Loja Teste", result.store_nome
    assert_includes result.store_endereco, "Rua A"
    assert_equal "São Paulo", result.store_cidade
    assert_equal "SP", result.store_uf
    assert_equal 1, result.items.size
    assert_equal "Arroz 5kg", result.items.first.descricao_bruta
    assert_equal BigDecimal("2"), result.items.first.quantidade
    assert_equal "UN", result.items.first.unidade
  end

  test "parses SVRS QrCodeNFce-style HTML with unit and line totals" do
    html = file_fixture("svrs_qrcode_nfce.html").read
    url = "https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=43260352932793000180650040000458781305092704|2|1|1|x"

    result = NfceConsultationParser.call(html, source_url: url)

    assert_equal "43260352932793000180650040000458781305092704", result.chave_acesso
    assert_equal "45878", result.numero
    assert_equal "4", result.serie
    assert_equal Date.new(2026, 3, 7), result.data_emissao
    assert_equal "21:18:01", result.hora_emissao
    assert_equal BigDecimal("36.80"), result.valor_total
    assert_equal "CAFÉ EXEMPLO COMERCIO LTDA ME", result.store_nome
    assert_equal 2, result.items.size

    first = result.items.first
    assert_includes first.descricao_bruta, "CAPPUCCINO"
    assert_equal "1002", first.codigo_estabelecimento
    assert_equal BigDecimal("1"), first.quantidade
    assert_equal "UN", first.unidade
    assert_equal BigDecimal("16.9"), first.valor_unitario
    assert_equal BigDecimal("16.90"), first.valor_total
  end

  test "chave_from_source_url reads p= first segment" do
    url = "https://dfe-portal.svrs.rs.gov.br/Dfe/QrCodeNFce?p=35250814255342000183650060000012341012345678%7C2%7C1"
    assert_equal "35250814255342000183650060000012341012345678",
      NfceConsultationParser.chave_from_source_url(url)
  end

  test "clean_store_nome strips SVRS heading glued to trade name" do
    parser = NfceConsultationParser.allocate
    raw = "DA NOTA FISCAL DE CONSUMIDOR ELETRÔNICAMIX COMERCIO DE SOVETES LTDA ME"
    assert_equal "MIX COMERCIO DE SOVETES LTDA ME", parser.send(:clean_store_nome_fragment, raw)
  end
end
