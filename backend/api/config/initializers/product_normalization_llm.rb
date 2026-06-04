# frozen_string_literal: true

# OpenRouter exposes an OpenAI-compatible API: POST https://openrouter.ai/api/v1/chat/completions
# Enable with PRODUCT_NORMALIZATION_LLM_ENABLED=true and OPENROUTER_API_KEY (free tier at openrouter.ai/keys).
Rails.application.config.product_normalization_llm = ActiveSupport::OrderedOptions.new.tap do |c|
  c.enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch("PRODUCT_NORMALIZATION_LLM_ENABLED", "false"))
  c.base_url = ENV.fetch("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1").to_s.sub(%r{/+\z}, "")
  c.model = ENV.fetch("OPENROUTER_MODEL", "nvidia/nemotron-3-ultra-550b-a55b:free")
  c.api_key = ENV.fetch("OPENROUTER_API_KEY", "")
  c.http_referer = ENV.fetch("OPENROUTER_HTTP_REFERER", "https://github.com/carrinho-certo")
  c.app_name = ENV.fetch("OPENROUTER_APP_NAME", "Carrinho Certo")
  c.open_timeout = ENV.fetch("OPENROUTER_OPEN_TIMEOUT", "10").to_i
  c.read_timeout = ENV.fetch("OPENROUTER_READ_TIMEOUT", "60").to_i
end
