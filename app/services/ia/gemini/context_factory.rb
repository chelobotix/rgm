module Ia
  module Gemini
    class ContextFactory
      include ::BaseService
      include Shared

      private attr_reader :context_type
      attr_reader :context

      ALLOWED_CONTEXT_TYPES = %i[ post_traduction_es post_traduction_pt ].freeze
      private_constant :ALLOWED_CONTEXT_TYPES

      def initialize(context_type:, dependencies_contexts: Dependencies.base_dependencies[:contexts])
        @context_type = context_type
        @dependencies_contexts = dependencies_contexts
        @context = nil
      end

      def call
        get_context
        set_as_valid!

      rescue ::Errors::StandardServiceError => e
        set_errors({ service: self.class, code: e.code, details: e.details })
        set_as_invalid!
      end

      private
      def get_context
        validate_context_type
        get_context_by_type
      end

      def validate_context_type
        if context_type.blank?
          raise_service_error(:CONTEXT_TYPE_ERROR, "Context type is required")
        end

        if ALLOWED_CONTEXT_TYPES.exclude?(context_type)
          raise_service_error(:CONTEXT_TYPE_ERROR, "Context type #{context_type} is not allowed")
        end
      end


      def get_context_by_type
        case context_type
        when :post_traduction_es
          @context = @dependencies_contexts.dig(:post_traduction_es).generate_context
        when :post_traduction_pt
          @context = @dependencies_contexts.dig(:post_traduction_pt).generate_context
        else
          raise_service_error(:CONTEXT_TYPE_ERROR, "Invalid context type")
        end
      end
    end
  end
end
