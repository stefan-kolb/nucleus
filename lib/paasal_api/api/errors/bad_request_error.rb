module Paasal
  module API
    module Errors
      class BadRequestError < ApiError
        # initialize with default error to be 400, bad request
        def initialize(message, ui_error = ErrorMessages::BAD_REQUEST)
          super(message, ui_error)
        end
      end
    end
  end
end
