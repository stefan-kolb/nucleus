module Paasal
  class AmbiguousAdapterError < StartupError

    def initialize(message)
      super(message, ExitCodes::STARTUP_ERROR)
    end

  end
end