module Paasal
  module Errors
    class AdapterMissingImplementationError < ApiError
      # initialize with default error to be 501
      def initialize(message, ui_error = API::ErrorMessages::MISSING_IMPLEMENTATION)
        super(message, ui_error)
      end
    end
  end
end
