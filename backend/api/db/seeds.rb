# frozen_string_literal: true

# Histórico de preços em Erechim (development). Pular: SKIP_ERECHIM_SEEDS=1
if !Rails.env.test? && (Rails.env.development? || ENV["SEED_ERECHIM_HISTORY"].present?)
  if ENV["SKIP_ERECHIM_SEEDS"] != "1"
    load Rails.root.join("db/seeds/erechim_market_history.rb")
    Seeds::ErechimMarketHistory.run!(force: ENV["SEED_ERECHIM_FORCE"] == "1")
  end
end
