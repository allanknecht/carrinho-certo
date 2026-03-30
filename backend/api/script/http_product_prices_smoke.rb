# frozen_string_literal: true

# Calls GET /products/:id/prices over HTTP (good end-to-end check from host → API).
# Run on the host (Ruby) or inside api container hitting localhost:3000.
#
# Env:
#   API_BASE_URL   default http://localhost:3000
#   API_EMAIL      required
#   API_PASSWORD   required
#   PRODUCT_ID     required (canonical product id)
#
# Example (PowerShell):
#   $env:API_EMAIL="appuser@example.com"; $env:API_PASSWORD="senha123456"
#   docker compose exec -T -e API_EMAIL=... -e API_PASSWORD=... api bin/rails runner script/http_product_prices_smoke.rb 1
#
# Note: from inside the container, API_BASE_URL=http://localhost:3000 only works if
# the Rails server is running in the same container; usually run this script on the
# host with Ruby, or use curl (see README).

require "net/http"
require "json"
require "uri"

base = ENV.fetch("API_BASE_URL", "http://localhost:3000").sub(%r{/+\z}, "")
email = ENV.fetch("API_EMAIL") { abort "set API_EMAIL" }
password = ENV.fetch("API_PASSWORD") { abort "set API_PASSWORD" }
product_id = ARGV[0].presence || ENV.fetch("PRODUCT_ID") { abort "usage: ... script/http_product_prices_smoke.rb <product_id>" }

uri = URI.parse("#{base}/auth/login")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = uri.scheme == "https"
login_req = Net::HTTP::Post.new(uri.request_uri)
login_req["Content-Type"] = "application/json"
login_req.body = JSON.generate(email: email, password: password)
login_res = http.request(login_req)
abort "login HTTP #{login_res.code}" unless login_res.code.to_i == 200

token = JSON.parse(login_res.body)["token"]
abort "no token" if token.blank?

uri = URI.parse("#{base}/products/#{product_id}/prices")
req = Net::HTTP::Get.new(uri.request_uri)
req["Authorization"] = "Bearer #{token}"
res = http.request(req)
puts "HTTP #{res.code}"
puts JSON.pretty_generate(JSON.parse(res.body))
exit 1 unless res.code.to_i == 200
