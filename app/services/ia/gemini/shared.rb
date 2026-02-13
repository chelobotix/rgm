module Ia
  module Gemini
    module Shared
      def raise_service_error(code, details)
        raise ::Errors::StandardServiceError.new(
          message: self.class.name,
          code: ErrorCodes::CODES[code],
          details: details
        )
      end
    end
  end
end
