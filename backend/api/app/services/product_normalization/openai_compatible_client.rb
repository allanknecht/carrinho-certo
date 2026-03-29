# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module ProductNormalization
  # Minimal OpenAI Chat Completions client (works with Ollama at /v1/chat/completions).
  class OpenaiCompatibleClient
    class Error < StandardError; end
    class HttpError < Error; end

    def initialize(base_url:, model:, api_key: "ollama", open_timeout: 5, read_timeout: 90)
      @base_url = base_url.to_s.sub(%r{/+\z}, "")
      @model = model
      @api_key = api_key
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    def chat_completion(messages)
      uri = URI.parse("#{@base_url}/chat/completions")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @open_timeout
      http.read_timeout = @read_timeout

      req = Net::HTTP::Post.new(uri.request_uri)
      req["Content-Type"] = "application/json"
      req["Authorization"] = "Bearer #{@api_key}"

      body = {
        model: @model,
        messages: messages,
        stream: false,
        temperature: 0.1
      }
      req.body = JSON.generate(body)

      res = http.request(req)
      unless res.code.to_i.between?(200, 299)
        raise HttpError, "HTTP #{res.code}: #{res.body.to_s.truncate(500)}"
      end

      parsed = JSON.parse(res.body)
      content = parsed.dig("choices", 0, "message", "content")
      raise Error, "empty completion" if content.blank?

      content.to_s
    end
  end
end
