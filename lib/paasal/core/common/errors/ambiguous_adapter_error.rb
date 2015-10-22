module Nucleus
  class AmbiguousAdapterError < StartupError
    def initialize(message)
      super(message, ExitCodes::STARTUP_ERROR)
    end
  end
end
