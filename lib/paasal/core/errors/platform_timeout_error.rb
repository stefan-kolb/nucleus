module Nucleus
  module Errors
    class PlatformTimeoutError < AdapterError
      # initialize with default error to be 504
      def initialize(message)
        super(message, ErrorMessages::PLATFORM_GATEWAY_TIMEOUT)
      end
    end
  end
end
