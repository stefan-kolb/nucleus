module Nucleus
  module Errors
    class UnknownAdapterCallError < AdapterError
      # initialize with default error to be 500
      def initialize(message, ui_error = ErrorMessages::RESCUED_ADAPTER_CALL)
        super(message, ui_error)
      end
    end
  end
end
