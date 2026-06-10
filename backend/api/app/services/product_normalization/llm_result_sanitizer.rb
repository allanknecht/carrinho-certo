# frozen_string_literal: true

module ProductNormalization
  # Corrects recurring LLM mistakes on known POS patterns before persisting.
  module LlmResultSanitizer
    module_function

    def call(descricao_bruta:, normalized_key:, display_name:)
      key = normalized_key.to_s
      name = display_name.to_s
      u = descricao_bruta.to_s.upcase

      if u.match?(/RACAO|RAÇÃO/) && !name.match?(/\bra[cç][aã]o\b/i)
        name = "Ração #{name}"
        key = "RACAO #{key}" unless key.start_with?("RACAO")
      end

      if u.match?(/DOCE\s+BAN\.?|DACOLONIA/) && (name.match?(/\bbanda\b/i) || key.match?(/\bBANDA\b/))
        name = name.sub(/\bbanda\b/i, "Banana")
        key = key.sub(/\ABANDA COLONIA\b/, "DOCE BANANA DA COLONIA")
        key = key.sub(/\ABANDA\b/, "DOCE BANANA")
        key = key.sub(/\bBANANA COLONIA\b/, "BANANA DA COLONIA") unless key.include?("DA COLONIA")
        name = name.sub(/\bBanana\s+Col[oô]nia\b/i, "Banana Da Colônia")
      end

      if u.include?("DOCE") && !name.match?(/\bdoce\b/i)
        name = "Doce #{name}"
        key = "DOCE #{key}" unless key.start_with?("DOCE")
      end

      if u.match?(/\bCHA\b/) && !name.match?(/\bch[aá]\b/i)
        name = "Chá #{name}"
        key = "CHA #{key}" unless key.start_with?("CHA")
      end

      if u.match?(/\bCAFE\b/) && !name.match?(/\bcaf[eé]\b/i)
        name = "Café #{name}"
        key = "CAFE #{key}" unless key.start_with?("CAFE")
      end

      { normalized_key: key, display_name: name }
    end
  end
end
