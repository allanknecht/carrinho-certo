# frozen_string_literal: true

ProductCanonical.order(:id).each do |p|
  puts "#{p.id} | #{p.normalized_key} | #{p.display_name}"
end
