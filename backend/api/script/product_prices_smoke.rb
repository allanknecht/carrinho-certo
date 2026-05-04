# frozen_string_literal: true

# Same JSON shape as GET /products/:id/prices but without HTTP (uses Rails env).
# Usage (from backend/api in Docker):
#   bin/rails runner script/product_prices_smoke.rb 1
#   bin/rails runner script/product_prices_smoke.rb 1 7
#
# Args: product_canonical_id (último preço por loja pela data de emissão no cupom).

id = ARGV[0]
abort "usage: bin/rails runner script/product_prices_smoke.rb <product_canonical_id>" if id.blank?

summary = Pricing::ProductPricesSummary.call(product_canonical_id: id.to_i)

if summary[:error] == :not_found
  warn "Product not found: id=#{id}"
  exit 1
end

puts JSON.pretty_generate(summary.except(:error))
