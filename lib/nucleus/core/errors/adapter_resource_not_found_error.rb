module Nucleus
  module Errors
    class AdapterResourceNotFoundError < AdapterError
      # initialize with default error to be 404, endpoint resource not found
      def initialize(message, ui_error = ErrorMessages::ENDPOINT_NOT_FOUND)
        super(message, ui_error)
      end
    end
  end
end
