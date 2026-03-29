# frozen_string_literal: true

module ProductNormalization
  # Single pipeline for matching: accent fold, uppercase, keep alphanumerics as word boundaries.
  module TextNormalizer
    module_function

    def normalize(text)
      s = ActiveSupport::Inflector.transliterate(text.to_s)
      s.upcase!
      s.gsub!(/[^A-Z0-9]+/, " ")
      s.squeeze!(" ")
      s.strip!
      s
    end
  end
end
