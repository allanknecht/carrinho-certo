# frozen_string_literal: true

load Rails.root.join("db/seeds/erechim_market_history.rb")

products = Seeds::ErechimMarketHistory::PRODUCTS.map do |meta|
  ProductCanonical.find_by!(normalized_key: meta[:key])
end

User.find_each do |user|
  Seeds::ErechimMarketHistory.ensure_comparison_list!(user: user, products: products)
  puts "OK #{user.email}"
end
