module Paasal
  module Errors
    class SemanticAdapterRequestError < ApiError
      # initialize with default error to be 422
      def initialize(message, error_code = nil, ui_error = API::ErrorMessages::BAD_REQUEST_ENTITY)
        # allow to customize the error code
        ui_error[:error_code] = error_code unless error_code.nil?
        super(message, ui_error)
      end
    end
  end
end
