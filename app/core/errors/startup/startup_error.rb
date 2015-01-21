module Paasal
  class StartupError < StandardError
    # exit code to use when exiting the application due to this error
    attr_accessor :exit_code

    # initialize with default exit code of ExitCodes::STARTUP_ERROR
    def initialize(message, exit_code=ExitCodes::STARTUP_ERROR)
      super(message)
      @exit_code = exit_code
    end
  end
end
