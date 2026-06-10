require "test_helper"

module ProductNormalization
  class PosAbbreviationHintsTest < ActiveSupport::TestCase
    test "includes banana and da colonia hints for doce ban dacolonia line" do
      hints = PosAbbreviationHints.for("DOCE BAN.DACOLONIA MAIS FIT 22G FRUTAS")

      assert hints.any? { |h| h.include?("banana") }
      assert hints.any? { |h| h.include?("Da Colônia") }
      assert hints.any? { |h| h.include?("Doce") }
    end

    test "includes racao hint for pet food line" do
      hints = PosAbbreviationHints.for("RACAO DOG CHOW ADUL.900G PEQ.CAR.FGO")

      assert hints.any? { |h| h.include?("Ração") }
    end
  end
end
