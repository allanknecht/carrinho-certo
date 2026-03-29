require "test_helper"

module ProductNormalization
  class TextNormalizerTest < ActiveSupport::TestCase
    test "folds accents and keeps alphanumerics" do
      assert_equal "COCA COLA 350ML", TextNormalizer.normalize("Coca-Cola 350ml")
    end

    test "collapses noise" do
      assert_equal "ARROZ TIPO 1 5KG", TextNormalizer.normalize("  Arroz  Tipo 1  5kg  ")
    end
  end
end
