module Paasal
  module Errors
    class SemanticAdapterRequestError < ApiError
      # initialize with default error to be 422
      def initialize(message, ui_error = API::ErrorMessages::BAD_REQUEST_ENTITY)
        super(message, ui_error)
      end
    end
  end
end
