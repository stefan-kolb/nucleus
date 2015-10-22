module Nucleus
  module Errors
    class PlatformUnavailableError < AdapterError
      # initialize with default error to be 503
      def initialize(message)
        super(message, ErrorMessages::UNAVAILABLE)
      end
    end
  end
end
