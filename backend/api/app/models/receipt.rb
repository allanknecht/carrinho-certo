class Receipt < ApplicationRecord
  belongs_to :user

  validates :source_url, presence: true
  validate :source_url_must_be_http_url

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
