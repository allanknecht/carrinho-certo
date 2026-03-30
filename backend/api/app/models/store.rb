class Store < ApplicationRecord
  has_many :receipts, dependent: :nullify
  has_many :observed_prices, dependent: :nullify, inverse_of: :store

  normalizes :cnpj, with: ->(c) { c.to_s.gsub(/\D/, "") }

  validates :cnpj, presence: true, uniqueness: true, length: { is: 14 }
  validates :nome, presence: true
  validates :uf, length: { maximum: 2 }, allow_blank: true
end
