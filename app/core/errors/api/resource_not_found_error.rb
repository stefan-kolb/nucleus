module Paasal
  module Errors
    class ResourceNotFoundError < ApiError
      # exit code to use when exiting the application due to this error
      attr_accessor :ui_error

      # initialize with default error to be 404, resource not found
      def initialize(message, ui_error=API::ErrorMessages::NOT_FOUND)
        super(message)
        @ui_error = ui_error
      end
    end
  end
end
