# frozen_string_literal: true

require "json"

module ProductNormalization
  # Second LLM pass: decide if the line is the same real product as one of the candidates.
  class LlmCatalogDisambiguator
    class Error < StandardError; end

    SYSTEM_PROMPT = <<~PROMPT.squish.freeze
      You deduplicate Brazilian NFC-e / retail catalog entries. The user lists ONE new line plus CANDIDATE products already in the database.
      Respond with ONLY a JSON object (no markdown) with keys:
      "decision" — either "merge" or "new";
      "product_canonical_id" — if merge, the integer id of exactly ONE candidate that is the SAME real-world product (same brand, variant, size where applicable); otherwise null;
      "reason" — one short sentence in Brazilian Portuguese.
      Use "merge" only when the POS line is clearly the same item as a candidate (e.g. abbreviation or typo of the same drink/SKU). Use "new" for different size, flavor, brand, or if unsure — prefer "new" when ambiguous.
      You must never invent an id: product_canonical_id must be one of the ids explicitly listed under candidates or null.
    PROMPT

    def self.call(descricao_bruta:, pos_normalized_key:, suggested_normalized_key:, suggested_display_name:, candidates:, client: nil)
      new(
        descricao_bruta:,
        pos_normalized_key:,
        suggested_normalized_key:,
        suggested_display_name:,
        candidates:,
        client:
      ).call
    end

    def initialize(descricao_bruta:, pos_normalized_key:, suggested_normalized_key:, suggested_display_name:, candidates:, client: nil)
      @descricao = descricao_bruta.to_s.strip
      @pos_key = pos_normalized_key.to_s
      @suggested_key = suggested_normalized_key.to_s
      @suggested_display = suggested_display_name.to_s
      @candidates = candidates
      @client = client
    end

    def call
      raise Error, "no candidates" if @candidates.blank?

      allowed_ids = @candidates.map(&:id)
      cfg = Rails.application.config.product_normalization_llm
      http = @client || OpenaiCompatibleClient.new(
        base_url: cfg.base_url,
        model: cfg.model,
        api_key: cfg.api_key,
        open_timeout: cfg.open_timeout,
        read_timeout: cfg.read_timeout
      )

      lines = @candidates.map { |c| %(id=#{c.id} normalized_key="#{c.normalized_key}" display_name="#{c.display_name}") }
      user = <<~TXT.squish
        POS raw line: #{@descricao}
        POS normalized: #{@pos_key}
        First-pass suggested canonical key: #{@suggested_key}
        First-pass suggested display_name: #{@suggested_display}
        Candidates (only these ids are valid for merge): #{lines.join(" | ")}
      TXT

      raw = http.chat_completion(
        [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: user }
        ]
      )

      parse(raw, allowed_ids)
    end

    private

    def parse(raw, allowed_ids)
      text = extract_json_object(raw)
      data = JSON.parse(text)
      decision = data["decision"].to_s.downcase.strip
      rid = data["product_canonical_id"]
      rid = rid.to_i if rid.present?
      reason = data["reason"].to_s

      raise Error, "invalid decision" unless %w[merge new].include?(decision)

      if decision == "merge"
        raise Error, "merge without id" unless rid.present? && allowed_ids.include?(rid)

        return { decision: "merge", product_canonical_id: rid, reason: reason }
      end

      { decision: "new", product_canonical_id: nil, reason: reason }
    rescue JSON::ParserError => e
      raise Error, "invalid JSON: #{e.message}"
    end

    def extract_json_object(raw)
      s = raw.to_s
      i = s.index("{")
      j = s.rindex("}")
      raise Error, "no JSON object" unless i && j && j > i

      s[i..j]
    end
  end
end
