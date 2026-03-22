# Receipt line as extracted from XML/HTML (before catalog product normalization).
# Main columns (see receipt_items_raw): descricao_bruta, codigo_estabelecimento, quantidade,
# unidade, valor_unitario, valor_total, ordem. Prices may be nil if the portal HTML omits
# them; NF-e XML usually includes values.
class ReceiptItemRaw < ApplicationRecord
  self.table_name = "receipt_items_raw"

  belongs_to :receipt

  validates :descricao_bruta, presence: true
  validates :ordem, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
