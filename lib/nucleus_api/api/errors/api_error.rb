module Nucleus
  module API
    module Errors
      class ApiError < StandardError
        # error constant to use when exiting the application due to this error
        attr_accessor :ui_error

        def initialize(message, ui_error)
          super(message)
          @ui_error = ui_error
        end
      end
    end
  end
end
