# frozen_string_literal: true

module ProductNormalization
  # Expands common Brazilian NFC-e POS truncations for the LLM user message.
  module PosAbbreviationHints
    module_function

    def for(descricao)
      u = descricao.to_s.upcase
      hints = []

      if u.match?(/RACAO|RAÇÃO/)
        hints << 'RACAO = ração (alimento para pet); manter "Ração" no display_name e RACAO no normalized_key'
      end
      if u.include?("DOCE")
        hints << 'DOCE = doce/bala; manter "Doce" no display_name e DOCE no normalized_key'
      end
      if u.match?(/BAN\.|DOCE\s+BAN/)
        hints << "BAN. = banana (nunca banda, ban ou barra)"
      end
      if u.match?(/DACOLONIA|DA\s*COLON/)
        hints << 'DACOLONIA = marca "Da Colônia" (não confundir com banana nem banda)'
      end
      if u.match?(/ADUL\.|ADUL\b/)
        hints << "ADUL. = adulto"
      end
      if u.match?(/PEQ\.|PEQ\b/)
        hints << "PEQ. = pequeno (porte/tamanho)"
      end
      if u.match?(/CAR\.|FGO/)
        hints << "CAR. = carne; FGO = frango"
      end
      if u.match?(/DESCAF\.|SAC\./)
        hints << "DESCAF. = descafeinado; SAC. = sachê"
      end
      if u.match?(/REQ\.|CREM\./)
        hints << "REQ.CREM. = requeijão cremoso"
      end
      if u.match?(/\bCHA\b/)
        hints << "CHA = chá; manter Chá no display_name"
      end
      if u.match?(/\bCAFE\b/)
        hints << "CAFE = café; manter Café no display_name"
      end

      hints
    end
  end
end
