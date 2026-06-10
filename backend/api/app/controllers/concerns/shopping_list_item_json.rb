# frozen_string_literal: true

module ShoppingListItemJson
  extend ActiveSupport::Concern

  private

  def shopping_list_item_payload(item)
    {
      id: item.id,
      product_canonical_id: item.product_canonical_id,
      product_name: item.product_canonical&.display_name || item.label,
      label: item.label,
      quantidade: format("%.3f", item.quantidade),
      ordem: item.ordem,
      created_at: item.created_at.iso8601(3),
      updated_at: item.updated_at.iso8601(3)
    }
  end
end
