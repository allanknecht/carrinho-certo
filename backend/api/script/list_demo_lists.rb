# frozen_string_literal: true

ShoppingList.where(name: "Lista teste comparativo").includes(:user).find_each do |list|
  puts "#{list.user.email}: #{list.shopping_list_items.count} itens (list_id=#{list.id})"
end
