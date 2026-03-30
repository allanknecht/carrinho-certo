# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment.
# The code can be executed at any point with `bin/rails db:seed`.

# Demo de preços (várias lojas / quantidade de notas) — só development, ou force com SEED_PRICING_DEMO=1.
# Pular: SKIP_PRICING_DEMO_SEEDS=1 bin/rails db:seed
if !Rails.env.test? && (Rails.env.development? || ENV["SEED_PRICING_DEMO"].present?)
  if ENV["SKIP_PRICING_DEMO_SEEDS"] != "1"
    load Rails.root.join("db/seeds/pricing_demo.rb")
    Seeds::PricingDemo.run!
  end
end
