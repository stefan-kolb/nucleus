module Nucleus
  module Errors
    # The {SemanticAdapterRequestError} shall be thrown if the user request could not be executed due to logical errors.
    # <br>
    # Examples for semantic errors are:
    #   - name already used
    #   - quota violations
    # <br>
    # These errors are clearly to be distinguished from malformed requests.
    class SemanticAdapterRequestError < AdapterError
      # initialize with default error to be 422
      def initialize(message, error_code = nil, ui_error = ErrorMessages::BAD_REQUEST_ENTITY)
        # allow to customize the error code
        ui_error[:error_code] = error_code unless error_code.nil?
        super(message, ui_error)
      end
    end
  end
end
