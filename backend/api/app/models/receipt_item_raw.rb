# Linha da nota como extraída do XML/HTML (antes de normalizar produto no catálogo).
# Colunas principais (schema em receipt_items_raw): descricao_bruta, codigo_estabelecimento,
# quantidade, unidade, valor_unitario, valor_total, ordem. Preços podem vir nil se o portal
# não expuser valores no HTML; no XML da NF-e costumam vir preenchidos.
class ReceiptItemRaw < ApplicationRecord
  self.table_name = "receipt_items_raw"

  belongs_to :receipt

  validates :descricao_bruta, presence: true
  validates :ordem, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
