require("net/http")
require("uri")

module Ia
  module Gemini
    class Fetcher
      include ::BaseService
      include Shared

      private attr_reader :message, :context
      attr_reader :result

      MODEL = "gemini-3-flash-preview"
      MAX_RETRIES = 3

      CONNECTION_ERRORS = [
        Net::OpenTimeout,
        Net::ReadTimeout,
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Errno::ETIMEDOUT,
        Errno::EHOSTUNREACH,
        Errno::ENETUNREACH,
        Errno::EPIPE,
        SocketError,
        OpenSSL::SSL::SSLError
      ].freeze
      private_constant :CONNECTION_ERRORS, :MODEL, :MAX_RETRIES

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

      rescue *CONNECTION_ERRORS => e
        set_errors({ service: self.class, code: ErrorCodes::CODES[:CONNECTION_ERROR], details: e.message })
        set_as_invalid!
      end

      private

      def handle_request
        (0..MAX_RETRIES).each do |attempt|
          request = build_request
          response = perform_request(request)

          if response.is_a?(Net::HTTPSuccess)
            return build_response(response.body)
          end

          next if attempt < MAX_RETRIES

          raise_service_error(:FETCH_ERROR, "Failed to fetch Gemini response: #{response.body}")
        end
      end

      def build_request
        uri = URI.parse("#{ENV.fetch("GEMINI_BASE_URL")}/models/#{MODEL}:generateContent")
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
        http.open_timeout = ENV.fetch("OPEN_TIME_OUT", "30").to_i
        http.read_timeout = ENV.fetch("READ_TIME_OUT", "30").to_i
        http.request(request)
      end

      def build_response(response)
        parsed_response = JSON.parse(response).with_indifferent_access
        text = parsed_response.dig(:candidates, 0, :content, :parts, 0, :text)

        if text.blank?
          raise_service_error(:NO_GEMINI_CANDIDATE, "No candidate found in Gemini response: #{response}")
        end

        parsed_text = JSON.parse(text).with_indifferent_access

        if parsed_text.dig(:translated_html).blank?
          raise_service_error(:NO_GEMINI_CANDIDATE, "No translated HTML found in Gemini response: #{response}")
        end

        @result = parsed_text.dig(:translated_html)

      rescue JSON::ParserError => e
        Rails.logger.error(e.message)
        raise_service_error(:PARSE_ERROR, "Failed to parse Gemini response: #{response}")
      end
    end
  end
end
