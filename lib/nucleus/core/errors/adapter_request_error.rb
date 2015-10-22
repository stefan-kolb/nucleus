module Nucleus
  module Errors
    class AdapterRequestError < AdapterError
      # initialize with default error to be 400
      def initialize(message, ui_error = ErrorMessages::ENDPOINT_BAD_REQUEST)
        super(message, ui_error)
      end
    end
  end
end
