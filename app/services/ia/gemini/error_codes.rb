module Ia
  module Gemini
    module ErrorCodes
      CODES = {
        MESSAGE_ERROR: 1000,
        CONTEXT_ERROR: 1001,
        API_KEY_ERROR: 1002,
        BASE_URL_ERROR: 1003,
        FETCH_ERROR: 1004,
        PARSE_ERROR: 1005,
        CONTEXT_TYPE_ERROR: 1006,
        READ_TIMEOUT_ERROR: 2000,
        OPEN_TIMEOUT_ERROR: 3000
      }.freeze
    end
  end
end
