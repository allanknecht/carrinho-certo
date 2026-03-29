# frozen_string_literal: true

# Local Ollama exposes an OpenAI-compatible API, e.g. POST http://localhost:11434/v1/chat/completions
# Enable with PRODUCT_NORMALIZATION_LLM_ENABLED=true and ensure Ollama is running (`ollama serve`).
Rails.application.config.product_normalization_llm = ActiveSupport::OrderedOptions.new.tap do |c|
  c.enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch("PRODUCT_NORMALIZATION_LLM_ENABLED", "false"))
  c.base_url = ENV.fetch("OLLAMA_OPENAI_BASE_URL", "http://localhost:11434/v1").to_s.sub(%r{/+\z}, "")
  c.model = ENV.fetch("OLLAMA_MODEL", "llama3.2")
  c.api_key = ENV.fetch("OLLAMA_API_KEY", "ollama")
  c.open_timeout = ENV.fetch("OLLAMA_OPEN_TIMEOUT", "5").to_i
  c.read_timeout = ENV.fetch("OLLAMA_READ_TIMEOUT", "90").to_i
end
