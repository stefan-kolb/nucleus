module Paasal
  module Errors
    class OAuth2AuthenticationError < AuthenticationError
      # initialize with default error to be 401, authentication failed
      def initialize(message, ui_error = API::ErrorMessages::ENDPOINT_AUTH_FAILED)
        super(message, ui_error)
      end
    end
  end
end
