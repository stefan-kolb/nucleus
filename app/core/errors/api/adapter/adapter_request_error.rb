module Paasal
  module Errors
    class AdapterRequestError < ApiError
      # initialize with default error to be 400/422
      def initialize(message, ui_error = API::ErrorMessages::ENDPOINT_BAD_REQUEST)
        super(message, ui_error)
      end
    end
  end
end
