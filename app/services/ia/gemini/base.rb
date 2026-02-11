module Ia
  module Gemini
    class Base
      include ::BaseService

      private attr_reader :message, :context_type, :context
      attr_reader :result

      def initialize(message:, context_type:, dependencies: Dependencies.base_dependencies)
        @message = message
        @context_type = context_type
        @dependencies = dependencies
        @context = nil
        @result = nil
      end

      def call
        debugger
        perform
        set_as_valid! if errors.blank?
      end

      private

      def perform
        flow = %w[ validator context_factory fetcher ]

        flow.each do |step|
          send(step)
          return if errors.present?
        end
      end

      def validator
        service = @dependencies[:validator].new(message: message, context_type: context_type)
        service.call

        unless service.valid?
          mark_as_invalid(service.errors)
        end
      end

      def context_factory
        service = @dependencies[:context_factory].new(context_type: context_type)
        service.call

        if service.valid?
          @context = service.context
        else
          mark_as_invalid(service.errors)
        end
      end

      def fetcher
        service = @dependencies[:fetcher].new(message: message, context: context)
        service.call

        if service.valid?
          @result = service.result
        else
          mark_as_invalid(service.errors)
        end
      end

      def mark_as_invalid(errors)
        set_as_invalid!
        set_errors(errors)
      end
    end
  end
end
