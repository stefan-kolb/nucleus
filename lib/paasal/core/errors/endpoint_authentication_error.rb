module Nucleus
  module Errors
    class EndpointAuthenticationError < AdapterError
      # initialize with default error to be 401, authentication failed
      def initialize(message, ui_error = ErrorMessages::AUTH_UNAUTHORIZED)
        super(message, ui_error)
      end
    end
  end
end
