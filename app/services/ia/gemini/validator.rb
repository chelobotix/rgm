module Ia
  module Gemini
    class Validator
      include ::BaseService
      include Shared

      private attr_reader :message, :context_type

      def initialize(message:, context_type:)
        @message = message
        @context_type = context_type
      end

      def call
        validate
        set_as_valid!

      rescue ::Errors::StandardServiceError => e
        set_errors({ service: self.class, code: e.code, details: e.details })
        set_as_invalid!
      end

      private

      def validate
        validator_methods = %w[ validate_message validate_context_type validate_api_key validate_base_url ]

        validator_methods.each do |validator_method|
          send(validator_method)
        end
      end

      def validate_message
        if message.blank?
          raise_service_error(:MESSAGE_ERROR, "Message is required")
        end
      end

      def validate_context_type
        if context_type.blank?
          raise_service_error(:CONTEXT_TYPE_ERROR, "Context type is required")
        end
      end

      def validate_api_key
        if ENV.fetch("GEMINI_API_KEY").blank?
          raise_service_error(:API_KEY_ERROR, "API key is empty")
        end
      end

      def validate_base_url
        if ENV.fetch("GEMINI_BASE_URL").blank?
          raise_service_error(:BASE_URL_ERROR, "Base URL is empty")
        end
      end
    end
  end
end
