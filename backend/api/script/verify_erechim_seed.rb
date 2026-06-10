# frozen_string_literal: true

load Rails.root.join("db/seeds/erechim_market_history.rb")

puts "=== Verificação Seeds::ErechimMarketHistory ==="

Seeds::ErechimMarketHistory::PRODUCTS.each do |meta|
  product = ProductCanonical.find_by(normalized_key: meta[:key])
  unless product
    puts "FALTA produto: #{meta[:name]}"
    next
  end

  rows = ObservedPrice.latest_rows_per_store_for_product(product.id).includes(:store).to_a
  erechim_rows = rows.select { |r| r.store&.cidade == Seeds::ErechimMarketHistory::CITY }

  if erechim_rows.size != 3
    puts "FALHA #{meta[:name]}: esperado 3 lojas em Erechim, tem #{erechim_rows.size}"
  else
    detail = erechim_rows.map { |r| "#{r.store.nome}=R$#{format('%.2f', r.valor_unitario)}" }.join(" | ")
    puts "OK #{meta[:name]}: #{detail}"
  end
end

list = ShoppingList.find_by(name: Seeds::ErechimMarketHistory::LIST_NAME)
if list
  result = Pricing::ShoppingListStoreTotals.call(shopping_list: list)
  full = result[:stores].select { |s| s[:lines_missing_price].zero? }
  puts "\nLista '#{list.name}' (#{list.shopping_list_items.count} itens):"
  full.each do |s|
    store = Store.find(s[:store_id])
    puts "  #{s[:nome]} (#{store.cidade}): total R$ #{s[:estimated_total]}"
  end
  best = full.min_by { |s| BigDecimal(s[:estimated_total]) }
  puts "Melhor mercado: #{best&.dig(:nome) || 'nenhum'}"
else
  puts "\nLista '#{Seeds::ErechimMarketHistory::LIST_NAME}' não encontrada"
end
