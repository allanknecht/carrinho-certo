class Receipt < ApplicationRecord
  belongs_to :user
  belongs_to :store, optional: true
  has_many :receipt_item_raws, class_name: "ReceiptItemRaw", dependent: :destroy, inverse_of: :receipt

  validates :source_url, presence: true
  validates :chave_acesso, length: { maximum: 44 }, allow_blank: true
  validate :source_url_must_be_http_url

  def self.chave_from_source_url(url)
    NfceConsultationParser.chave_from_source_url(url)
  end

  private

  def source_url_must_be_http_url
    return if source_url.blank?

    uri = URI.parse(source_url)
    unless uri.is_a?(URI::HTTP) && uri.host.present?
      errors.add(:source_url, "is invalid")
    end
  rescue URI::InvalidURIError
    errors.add(:source_url, "is invalid")
  end
end
