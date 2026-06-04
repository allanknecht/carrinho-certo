# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module ProductNormalization
  # Minimal OpenAI Chat Completions client (OpenRouter, OpenAI, etc.).
  class OpenaiCompatibleClient
    class Error < StandardError; end
    class HttpError < Error; end

    def initialize(base_url:, model:, api_key: "", open_timeout: 10, read_timeout: 60, http_referer: nil, app_name: nil)
      @base_url = base_url.to_s.sub(%r{/+\z}, "")
      @model = model
      @api_key = api_key
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @http_referer = http_referer
      @app_name = app_name
    end

    def chat_completion(messages)
      uri = URI.parse("#{@base_url}/chat/completions")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @open_timeout
      http.read_timeout = @read_timeout

      req = Net::HTTP::Post.new(uri.request_uri)
      req["Content-Type"] = "application/json"
      req["Authorization"] = "Bearer #{@api_key}" if @api_key.present?
      req["HTTP-Referer"] = @http_referer if @http_referer.present?
      req["X-Title"] = @app_name if @app_name.present?

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
