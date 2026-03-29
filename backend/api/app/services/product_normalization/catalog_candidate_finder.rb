# frozen_string_literal: true

module ProductNormalization
  # Cheap retrieval of ProductCanonical rows that might be the same item as a new line
  # (token overlap on normalized_key / display_name + recently touched rows).
  class CatalogCandidateFinder
    DEFAULT_MAX = 20
    RECENT = 8
    MIN_TOKEN_LEN = 3

    def self.call(pos_normalized_key:, suggested_normalized_key:, max: DEFAULT_MAX)
      tokens = token_set(pos_normalized_key, suggested_normalized_key)
      ids = []

      tokens.each do |tok|
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(tok)}%"
        ProductCanonical.where("normalized_key ILIKE ?", pattern).limit(10).pluck(:id).each { |id| ids << id }
        ProductCanonical.where("display_name ILIKE ?", pattern).limit(10).pluck(:id).each { |id| ids << id }
      end

      ProductCanonical.order(updated_at: :desc).limit(RECENT).pluck(:id).each { |id| ids << id }

      ProductCanonical.where(id: ids.uniq).order(:id).limit(max)
    end

    def self.token_set(pos, sug)
      (pos.to_s.split + sug.to_s.split).map(&:strip).uniq.reject { |t| t.length < MIN_TOKEN_LEN }
    end
  end
end
