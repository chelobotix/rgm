require("net/http")
require("uri")

module Ia
  module Gemini
    class Fetcher
      include ::BaseService
      include Shared

      private attr_reader :message, :context
      attr_reader :result

      def initialize(message:, context:)
        @message = message
        @context = context
        @result = nil
      end

      def call
        handle_request
        set_as_valid! if errors.blank?

      rescue ::Errors::StandardServiceError => e
        set_errors({ service: self.class, code: e.code, details: e.details })
        set_as_invalid!

      rescue Net::ReadTimeout => e
        set_errors({ service: self.class, code: ErrorCodes::CODES[:READ_TIMEOUT_ERROR], details: e.message })
        set_as_invalid!

      rescue Net::OpenTimeout => e
        set_errors({ service: self.class, code: ErrorCodes::CODES[:OPEN_TIMEOUT_ERROR], details: e.message })
        set_as_invalid!
      end

      private

      def handle_request
        debugger
        models = [ "gemini-3-flash-preview", "gemini-2.0-flash" ]

        models.each_with_index do |model, index|
          break if result.present?

          request = build_request(model)
          response = perform_request(request)
          handle_response(request, response, index)
        end

      rescue JSON::ParserError => e
        Rails.logger.error(e.message)
        raise_service_error(:PARSE_ERROR, "Failed to parse Gemini response: #{response.body}")
      end

      def build_request(model)
        uri = URI.parse("#{ENV.fetch("GEMINI_BASE_URL")}/models/#{model}:generateContent")
        request = Net::HTTP::Post.new(uri)
        request["x-goog-api-key"] = ENV.fetch("GEMINI_API_KEY")
        request["Content-Type"] = "application/json"
        request.body = build_body.to_json
        request
      end

      def build_body
        {
          contents: [
            {
              parts: [
                {
                  text: "#{context} #{message}"
                }
              ]
            }
          ]
        }
      end

      def perform_request(request)
        http = Net::HTTP.new(request.uri.host, request.uri.port)
        http.use_ssl = true
        http.open_timeout = 30
        http.read_timeout = 30
        http.request(request)
      end

      def handle_response(request, response, attempt)
        unless response.is_a?(Net::HTTPSuccess)
          return if attempt == 0

          raise_service_error(:FETCH_ERROR, "Failed to fetch Gemini response: #{response.body}")
        end
        debugger
        parsed_response = JSON.parse(response.body).with_indifferent_access
        build_response(parsed_response)
      end

      def build_response(parsed_response)
        text = parsed_response.dig(:candidates, 0, :content, :parts, 0, :text)
        parsed_text = JSON.parse(text).with_indifferent_access
        @result = parsed_text.dig(:translated_html)
      end
    end
  end
end
