module Paasal
  module Errors
    # The {AdapterMissingImplementationError} shall be thrown when the API requests an adapter to execute an action,
    # e.g. update an application, but the adapter does not (yet) support this functionality.
    class AdapterMissingImplementationError < AdapterError
      # initialize with default error to be 501
      def initialize(message, ui_error = API::ErrorMessages::MISSING_IMPLEMENTATION)
        super(message, ui_error)
      end
    end
  end
end
