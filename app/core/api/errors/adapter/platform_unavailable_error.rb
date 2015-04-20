module Paasal
  module Errors
    class PlatformUnavailableError < ApiError
      # initialize with default error to be 503
      def initialize(message)
        super(message, API::ErrorMessages::UNAVAILABLE)
      end
    end
  end
end
