# frozen_string_literal: true

require "json"

module ProductNormalization
  # Asks an OpenAI-compatible endpoint (Ollama) for a stable product key + display name.
  class LlmCanonicalResolver
    class Error < StandardError; end

    SYSTEM_PROMPT = <<~PROMPT.squish.freeze
      You normalize Brazilian NFC-e / supermarket / café receipt line items for price comparison across stores.
      Reply with ONLY a JSON object (no markdown, no code fences) with exactly two string keys:
      "normalized_key" — UPPERCASE ASCII letters, digits, and SINGLE spaces between words (max 80 chars). Use one space between every word; never concatenate separate words (e.g. write "COCA COLA" not "COCACOLA"). Strip accents via ASCII equivalents (CAFE not CAFÉ). Include volume/size when printed on the line (e.g. 350ML, 2L). Treat common POS abbreviations in context: in beverages "GLD" or "GEL" usually means GELADO (iced), "LT" means LATA (can), "PET" plastic bottle, "UN" is unit not part of the name.
      "display_name" — short natural Brazilian Portuguese for the shopper UI (accents allowed), max 120 chars.
      Same physical product must always get the same normalized_key even if the POS description changes.
    PROMPT

    def self.call(descricao_bruta:, client: nil)
      new(descricao_bruta:, client:).call
    end

    def initialize(descricao_bruta:, client: nil)
      @descricao = descricao_bruta.to_s.strip
      @client = client
    end

    def call
      raise Error, "blank description" if @descricao.blank?

      cfg = Rails.application.config.product_normalization_llm
      http = @client || OpenaiCompatibleClient.new(
        base_url: cfg.base_url,
        model: cfg.model,
        api_key: cfg.api_key,
        open_timeout: cfg.open_timeout,
        read_timeout: cfg.read_timeout
      )

      raw = http.chat_completion(
        [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: "Descrição na nota: #{@descricao}" }
        ]
      )

      parse_json_payload(raw)
    end

    private

    def parse_json_payload(raw)
      text = extract_json_object(raw)
      data = JSON.parse(text)
      key = data["normalized_key"].to_s
      name = data["display_name"].to_s
      raise Error, "missing keys" if key.blank? || name.blank?

      { normalized_key: key, display_name: name }
    rescue JSON::ParserError => e
      raise Error, "invalid JSON from model: #{e.message}"
    end

    def extract_json_object(raw)
      s = raw.to_s
      i = s.index("{")
      j = s.rindex("}")
      raise Error, "no JSON object in model output" unless i && j && j > i

      s[i..j]
    end
  end
end
