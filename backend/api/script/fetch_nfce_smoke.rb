# frozen_string_literal: true

# Usage (from backend/api): bin/rails runner script/fetch_nfce_smoke.rb 'https://dfe-portal...QrCodeNFce?p=...'
# Fetches the consultation URL and prints parser output (no DB writes).

require "net/http"

url = ARGV[0]
abort "usage: bin/rails runner script/fetch_nfce_smoke.rb <consultation_url>" if url.blank?

uri = URI(url)
abort "only http/https" unless uri.is_a?(URI::HTTP)

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = uri.scheme == "https"
http.open_timeout = 15
http.read_timeout = 25
req = Net::HTTP::Get.new(uri.request_uri)
req["User-Agent"] = "CarrinhoCerto/1.0"
res = http.request(req)
abort "HTTP #{res.code}" unless res.code.to_i.between?(200, 299)

parsed = NfceConsultationParser.call(res.body, source_url: url)
puts "chave=#{parsed.chave_acesso}"
puts "numero=#{parsed.numero} serie=#{parsed.serie} data=#{parsed.data_emissao} total=#{parsed.valor_total}"
puts "cnpj=#{parsed.store_cnpj}"
puts "items=#{parsed.items.size}"
parsed.items.each do |i|
  puts "  - #{i.descricao_bruta.inspect} cod=#{i.codigo_estabelecimento} q=#{i.quantidade} un=#{i.unidade.inspect} vu=#{i.valor_unitario} vt=#{i.valor_total}"
end
