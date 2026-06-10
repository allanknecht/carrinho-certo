require "test_helper"

module ProductNormalization
  class LlmResultSanitizerTest < ActiveSupport::TestCase
    test "prepends Ração when raw line has RACAO but LLM dropped it" do
      result = LlmResultSanitizer.call(
        descricao_bruta: "RACAO DOG CHOW ADUL.900G PEQ.CAR.FGO",
        normalized_key: "DOG CHOW ADULTO 900G PEQUENO PORTE CARNE FRANGO",
        display_name: "Dog Chow Adulto 900g"
      )

      assert_match(/\bRação\b/i, result[:display_name])
      assert result[:normalized_key].start_with?("RACAO")
    end

    test "fixes banda colonia misread as banana da colonia" do
      result = LlmResultSanitizer.call(
        descricao_bruta: "DOCE BAN.DACOLONIA MAIS FIT 22G FRUTAS",
        normalized_key: "BANDA COLONIA MAIS FIT 22G FRUTAS",
        display_name: "Banda Colônia Mais Fit 22g Frutas"
      )

      assert_match(/Banana/i, result[:display_name])
      assert_no_match(/banda/i, result[:display_name])
      assert_includes result[:normalized_key], "BANANA DA COLONIA"
      assert_no_match(/BANDA/, result[:normalized_key])
      assert_match(/Da Colônia/i, result[:display_name])
    end

    test "prepends Doce when raw line has DOCE but LLM dropped it" do
      result = LlmResultSanitizer.call(
        descricao_bruta: "DOCE BAN.DACOLONIA MAIS FIT 22G FRUTAS",
        normalized_key: "BANANA DA COLONIA MAIS FIT 22G",
        display_name: "Banana Da Colônia Mais Fit 22g"
      )

      assert_match(/\bDoce\b/i, result[:display_name])
      assert result[:normalized_key].start_with?("DOCE")
    end
  end
end
