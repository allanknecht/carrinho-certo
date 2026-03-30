# frozen_string_literal: true

# bin/rails runner script/show_normalized_lines.rb
ReceiptItemRaw.order(:receipt_id, :ordem).each do |l|
  next unless l.product_canonical

  puts "#{l.descricao_bruta} -> #{l.product_canonical.display_name} (#{l.normalization_source})"
end
