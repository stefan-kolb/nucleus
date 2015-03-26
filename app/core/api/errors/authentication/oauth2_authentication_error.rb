module Paasal
  module Errors
    class OAuth2AuthenticationError < AuthenticationError
      # reference to the auth client that failed
      attr_accessor :o2auth_client

      # initialize with default error to be 401, authentication failed
      def initialize(message, o2auth_client, ui_error = API::ErrorMessages::ENDPOINT_AUTH_FAILED)
        super(message, ui_error)
        @o2auth_client = o2auth_client
      end
    end
  end
end
