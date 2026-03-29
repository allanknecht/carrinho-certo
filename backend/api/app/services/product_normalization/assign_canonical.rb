# frozen_string_literal: true

module ProductNormalization
  # Resolves receipt_items_raw.product_canonical_id using aliases first, then exact
  # normalized_key on ProductCanonical. New products: optional OpenAI-compatible LLM
  # (Ollama local) when enabled; otherwise creates a canonical from the text pipeline.
  class AssignCanonical
    def self.call(receipt_item_raw)
      new(receipt_item_raw).call
    end

    def initialize(receipt_item_raw)
      @row = receipt_item_raw
    end

    def call
      key = TextNormalizer.normalize(@row.descricao_bruta)
      if key.blank?
        @row.update_columns(product_canonical_id: nil, normalization_source: nil, updated_at: Time.current)
        return
      end

      product, source = resolve(key)
      @row.update_columns(
        product_canonical_id: product.id,
        normalization_source: source,
        updated_at: Time.current,
      )
    end

    private

    def resolve(key)
      if (pa = ProductAlias.find_by(alias_normalized: key))
        return [pa.product_canonical, "alias"]
      end

      if (pc = ProductCanonical.find_by(normalized_key: key))
        return [pc, "canonical_key"]
      end

      if llm_enabled?
        result = resolve_via_llm(key)
        return result if result
      end

      heuristic_create(key)
    end

    def llm_enabled?
      Rails.application.config.product_normalization_llm.enabled
    end

    # Maps this POS-normalized label to a canonical suggested by the LLM; optional second
    # LLM pass merges with an existing catalog row when candidates look like the same SKU.
    def resolve_via_llm(pos_normalized_key)
      llm = LlmCanonicalResolver.call(descricao_bruta: @row.descricao_bruta)
      llm_key = TextNormalizer.normalize(llm[:normalized_key])
      return nil if llm_key.blank?

      display = llm[:display_name].to_s.strip.squeeze(" ").truncate(200, omission: "")
      display = llm_key if display.blank?

      pc, source = resolve_llm_product(pos_normalized_key, llm_key, display)
      return nil if pc.blank?

      existing = ProductAlias.find_by(alias_normalized: pos_normalized_key)
      return [existing.product_canonical, "alias"] if existing

      alias_source = source.to_s == "llm_merge" ? "llm_merge" : "llm"
      ProductAlias.create!(product_canonical: pc, alias_normalized: pos_normalized_key, source: alias_source)
      [pc, source]
    rescue StandardError => e
      Rails.logger.warn("[ProductNormalization] LLM failed: #{e.class}: #{e.message}")
      nil
    end

    def resolve_llm_product(pos_normalized_key, llm_key, display)
      if (exact = ProductCanonical.find_by(normalized_key: llm_key))
        return [exact, "llm"]
      end

      candidates = CatalogCandidateFinder.call(
        pos_normalized_key: pos_normalized_key,
        suggested_normalized_key: llm_key
      )

      if candidates.any?
        begin
          decision = LlmCatalogDisambiguator.call(
            descricao_bruta: @row.descricao_bruta,
            pos_normalized_key: pos_normalized_key,
            suggested_normalized_key: llm_key,
            suggested_display_name: display,
            candidates: candidates
          )
          if decision[:decision] == "merge" && decision[:product_canonical_id].present?
            merged = ProductCanonical.find_by(id: decision[:product_canonical_id])
            if merged && candidates.map(&:id).include?(merged.id)
              Rails.logger.info("[ProductNormalization] LLM merge → product_canonical_id=#{merged.id} (#{decision[:reason]})")
              return [merged, "llm_merge"]
            end
          end
        rescue StandardError => e
          Rails.logger.warn("[ProductNormalization] LLM disambiguation skipped: #{e.class}: #{e.message}")
        end
      end

      created = ProductCanonical.create!(normalized_key: llm_key, display_name: display)
      [created, "llm"]
    end

    def heuristic_create(key)
      display = @row.descricao_bruta.to_s.strip.squeeze(" ").truncate(200, omission: "")
      display = key if display.blank?
      pc = ProductCanonical.create!(normalized_key: key, display_name: display)
      [pc, "new_canonical"]
    end
  end
end
