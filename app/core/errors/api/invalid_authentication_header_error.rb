module Paasal
  module Errors
    class InvalidAuthenticationHeaderError < ApiError
      # initialize with default error to be 401, authentication failed
      def initialize(message, ui_error=API::ErrorMessages::AUTH_UNAUTHORIZED)
        super(message, ui_error)
      end
    end
  end
end
