module Ia
  module Gemini
    module Dependencies
      def self.base_dependencies
        {
          validator: Validator,
          fetcher: Fetcher,
          context_factory: ContextFactory,
          contexts: {
            post_traduction_es: Gemini::Contexts::PostTraductionEs
            # post_traduction_pt: Gemini::Contexts::PostTraductionPt
          }
        }
      end
    end
  end
end
