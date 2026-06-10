# frozen_string_literal: true

require "json"

module ProductNormalization
  # Asks an OpenAI-compatible endpoint (OpenRouter) for a stable product key + display name.
  class LlmCanonicalResolver
    class Error < StandardError; end

    SYSTEM_PROMPT = <<~PROMPT.squish.freeze
      You normalize Brazilian NFC-e / supermarket receipt line items for price comparison across stores.
      Reply with ONLY a JSON object (no markdown, no code fences) with exactly two string keys:
      "normalized_key" — UPPERCASE ASCII letters, digits, and SINGLE spaces between words (max 80 chars). One space between words; never concatenate (e.g. "COCA COLA" not "COCACOLA"). Strip accents (CAFE not CAFÉ). Include size when printed (350ML, 900G, 22G, KG). Expand POS abbreviations in the key: RACAO=ração, DOCE=doce/bala, BAN.=banana, DACOLONIA=Da Colônia, ADUL.=adulto, PEQ.=pequeno, CAR.=carne, FGO=frango, DESCAF.=descafeinado, SAC.=sachê, REQ.CREM.=requeijão cremoso, CHA=chá, CAFE=café, GLD/GEL=gelado, LT=lata, PET=garrafa PET. Keep the product CATEGORY token when present (RACAO, DOCE, CHA, CAFE, QUEIJO, BATATA, REQ) — never drop it.
      "display_name" — short Brazilian Portuguese for the shopper UI (accents allowed), max 120 chars, prefer under ~55 chars. Pattern: **category (when essential) + brand + variant + size**. Keep category words that define what the product IS: Ração, Doce, Chá, Café, Queijo, Batata, Requeijão. Beverages: brand + packaging + size; omit redundant flavor if obvious. Never misread POS truncations: BAN. after DOCE is banana, not "banda"; DACOLONIA is the brand "Da Colônia".
      Examples (follow this style):
      "RACAO DOG CHOW ADUL.900G PEQ.CAR.FGO" → normalized_key: "RACAO DOG CHOW ADULTO 900G PEQUENO CARNE FRANGO", display_name: "Ração Dog Chow Adulto 900g Peq."
      "DOCE BAN.DACOLONIA MAIS FIT 22G FRUTAS" → normalized_key: "DOCE BANANA DA COLONIA MAIS FIT 22G FRUTAS", display_name: "Doce Banana Da Colônia Mais Fit 22g"
      "CAFE SOLUVEL IGUACU DESCAF.SAC.40G" → normalized_key: "CAFE SOLUVEL IGUACU DESCAFEINADO SACHE 40G", display_name: "Café Solúvel Iguaçu Descaf. 40g"
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
        read_timeout: cfg.read_timeout,
        http_referer: cfg.http_referer,
        app_name: cfg.app_name,
      )

      raw = http.chat_completion(
        [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: build_user_prompt },
        ]
      )

      parse_json_payload(raw)
    end

    private

    def build_user_prompt
      parts = ["Descrição na nota (texto literal do cupom): #{@descricao}"]
      hints = PosAbbreviationHints.for(@descricao)
      if hints.any?
        parts << "Expansão obrigatória de abreviações POS nesta linha: #{hints.join(' | ')}"
      end
      parts.join("\n")
    end

    def parse_json_payload(raw)
      text = extract_json_object(raw)
      data = JSON.parse(text)
      key = data["normalized_key"].to_s
      name = data["display_name"].to_s
      raise Error, "missing keys" if key.blank? || name.blank?

      LlmResultSanitizer.call(descricao_bruta: @descricao, normalized_key: key, display_name: name)
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
