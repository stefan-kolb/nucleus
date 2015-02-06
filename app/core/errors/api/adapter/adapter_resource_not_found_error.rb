module Paasal
  module Errors
    class AdapterResourceNotFoundError < ApiError
      # initialize with default error to be 404, endpoint resource not found
      def initialize(message, ui_error = API::ErrorMessages::ENDPOINT_NOT_FOUND)
        super(message, ui_error)
      end
    end
  end
end
