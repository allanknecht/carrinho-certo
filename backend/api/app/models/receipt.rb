class Receipt < ApplicationRecord
  belongs_to :user
  belongs_to :store, optional: true
  has_many :receipt_item_raws, class_name: "ReceiptItemRaw", dependent: :destroy, inverse_of: :receipt

  validates :source_url, presence: true
  validates :chave_acesso, length: { maximum: 44 }, allow_blank: true
  validate :source_url_must_be_http_url
  validate :chave_acesso_must_be_44_digits_if_present

  def self.chave_from_source_url(url)
    NfceConsultationParser.chave_from_source_url(url)
  end

  private

  def chave_acesso_must_be_44_digits_if_present
    return if chave_acesso.blank?

    errors.add(:chave_acesso, "must be exactly 44 digits") unless chave_acesso.to_s.match?(/\A\d{44}\z/)
  end

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
