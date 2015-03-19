module Paasal
  module Errors
    class ApplicationArchiveError < ApiError
      def initialize(message, ui_error = API::ErrorMessages::BAD_REQUEST_APP_ARCHIVE)
        super(message, ui_error)
      end
    end
  end
end
