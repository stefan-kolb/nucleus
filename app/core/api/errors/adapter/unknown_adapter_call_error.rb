module Paasal
  module Errors
    class UnknownAdapterCallError < ApiError
      # initialize with default error to be 500
      def initialize(message, ui_error = API::ErrorMessages::RESCUED_ADAPTER_CALL)
        super(message, ui_error)
      end
    end
  end
end
