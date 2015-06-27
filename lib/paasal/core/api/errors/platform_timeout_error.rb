module Paasal
  module Errors
    class PlatformTimeoutError < AdapterError
      # initialize with default error to be 504
      def initialize(message)
        super(message, API::ErrorMessages::PLATFORM_GATEWAY_TIMEOUT)
      end
    end
  end
end
