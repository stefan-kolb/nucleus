module Paasal
  module API
    module Errors
      class ResourceNotFoundError < ApiError
        # initialize with default error to be 404, resource not found
        def initialize(message, ui_error = API::ErrorMessages::NOT_FOUND)
          super(message, ui_error)
        end
      end
    end
  end
end
