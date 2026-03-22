class User < ApplicationRecord
  has_secure_password

  has_many :receipts, dependent: :destroy

  normalizes :email, with: ->(e) { e.to_s.downcase.strip }

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  generates_token_for :api, expires_in: 30.days do
    [ id, email ]
  end
end
