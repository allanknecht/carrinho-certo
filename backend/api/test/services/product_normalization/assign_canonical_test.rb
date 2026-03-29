require "test_helper"

module ProductNormalization
  class AssignCanonicalTest < ActiveSupport::TestCase
    test "creates canonical from normalized description when unknown" do
      receipt = receipts(:one)
      token = SecureRandom.hex(4)
      desc = "UniqueProduct #{token}"
      row = receipt.receipt_item_raws.create!(descricao_bruta: "  #{desc}  ", ordem: 0)

      AssignCanonical.call(row)
      row.reload

      assert row.product_canonical_id.present?
      assert_equal "new_canonical", row.normalization_source
      assert_equal TextNormalizer.normalize(desc), row.product_canonical.normalized_key
    end

    test "reuses canonical when normalized_key already exists" do
      receipt = receipts(:one)
      token = SecureRandom.hex(4)
      key = "EXISTING KEY #{token}"
      normalized = TextNormalizer.normalize(key)
      ProductCanonical.create!(normalized_key: normalized, display_name: "Existing #{token}")

      row = receipt.receipt_item_raws.create!(descricao_bruta: key.downcase, ordem: 0)
      AssignCanonical.call(row)
      row.reload

      assert_equal "canonical_key", row.normalization_source
      assert_equal 1, ProductCanonical.where(normalized_key: normalized).count
    end

    test "alias wins over different normalized string" do
      receipt = receipts(:one)
      token = SecureRandom.hex(4)
      canonical = ProductCanonical.create!(
        normalized_key: "CANONICAL COCA #{token}",
        display_name: "Coca #{token}"
      )
      variant = "COCA VARIANT #{token}"
      variant_key = TextNormalizer.normalize(variant)
      ProductAlias.create!(product_canonical: canonical, alias_normalized: variant_key, source: "manual")

      row = receipt.receipt_item_raws.create!(descricao_bruta: variant, ordem: 0)
      AssignCanonical.call(row)
      row.reload

      assert_equal "alias", row.normalization_source
      assert_equal canonical.id, row.product_canonical_id
    end

    test "clears assignment when description normalizes to blank" do
      receipt = receipts(:one)
      row = receipt.receipt_item_raws.create!(descricao_bruta: "@@@", ordem: 0)
      AssignCanonical.call(row)
      row.reload

      assert_nil row.product_canonical_id
      assert_nil row.normalization_source
    end

    test "uses OpenAI-compatible LLM path when enabled and records llm alias" do
      cfg = Rails.application.config.product_normalization_llm
      prev = cfg.enabled
      cfg.enabled = true

      receipt = receipts(:one)
      token = SecureRandom.hex(4)
      desc = "Refrig cola lata #{token}"
      row = receipt.receipt_item_raws.create!(descricao_bruta: desc, ordem: 0)
      pos_key = TextNormalizer.normalize(desc)

      llm_response = lambda do |**_kwargs|
        { normalized_key: "COLA LATA 350ML #{token}", display_name: "Refrigerante cola 350ml" }
      end

      empty_candidates = ProductCanonical.none
      CatalogCandidateFinder.stub(:call, empty_candidates) do
        LlmCanonicalResolver.stub(:call, llm_response) do
          AssignCanonical.call(row)
        end
      end

      row.reload
      expected_llm_key = TextNormalizer.normalize("COLA LATA 350ML #{token}")

      assert_equal "llm", row.normalization_source
      assert_equal expected_llm_key, row.product_canonical.normalized_key

      pa = ProductAlias.find_by(alias_normalized: pos_key)
      assert_equal "llm", pa.source
      assert_equal row.product_canonical_id, pa.product_canonical_id
    ensure
      cfg.enabled = prev
    end

    test "falls back to heuristic when LLM is enabled but call fails" do
      cfg = Rails.application.config.product_normalization_llm
      prev = cfg.enabled
      cfg.enabled = true

      receipt = receipts(:one)
      token = SecureRandom.hex(4)
      desc = "FallbackLLM #{token}"
      row = receipt.receipt_item_raws.create!(descricao_bruta: desc, ordem: 0)

      CatalogCandidateFinder.stub(:call, ProductCanonical.none) do
        LlmCanonicalResolver.stub(:call, lambda { |**_| raise LlmCanonicalResolver::Error, "offline" }) do
          AssignCanonical.call(row)
        end
      end

      row.reload
      assert_equal "new_canonical", row.normalization_source
      assert_equal TextNormalizer.normalize(desc), row.product_canonical.normalized_key
    ensure
      cfg.enabled = prev
    end

    test "LLM merge attaches to existing canonical when disambiguator says merge" do
      cfg = Rails.application.config.product_normalization_llm
      prev = cfg.enabled
      cfg.enabled = true

      receipt = receipts(:one)
      existing = ProductCanonical.create!(
        normalized_key: "CAFE GELADO CARAMELO",
        display_name: "Café gelado caramelo"
      )
      row = receipt.receipt_item_raws.create!(descricao_bruta: "cafe gld caramel", ordem: 0)
      candidates = ProductCanonical.where(id: existing.id)

      merge_decision = { decision: "merge", product_canonical_id: existing.id, reason: "mesmo item" }

      CatalogCandidateFinder.stub(:call, candidates) do
        LlmCanonicalResolver.stub(:call, lambda { |**_|
          { normalized_key: "CAFE GOLD CARAMEL", display_name: "Café gold caramel" }
        }) do
          LlmCatalogDisambiguator.stub(:call, lambda { |**_| merge_decision }) do
            AssignCanonical.call(row)
          end
        end
      end

      row.reload
      assert_equal existing.id, row.product_canonical_id
      assert_equal "llm_merge", row.normalization_source
      assert_equal 1, ProductCanonical.where(normalized_key: "CAFE GELADO CARAMELO").count
      pa = ProductAlias.find_by(alias_normalized: TextNormalizer.normalize("cafe gld caramel"))
      assert_equal "llm_merge", pa.source
      assert_equal existing.id, pa.product_canonical_id
    ensure
      cfg.enabled = prev
    end
  end
end
