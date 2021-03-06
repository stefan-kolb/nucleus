module Nucleus
  module Errors
    class AdapterError < StandardError
      # error constant to use when exiting the application due to this error
      attr_accessor :ui_error

      def initialize(message, ui_error)
        super(message)
        @ui_error = ui_error
      end
    end
  end
end
