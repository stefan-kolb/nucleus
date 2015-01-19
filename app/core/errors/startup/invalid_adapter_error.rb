module Paasal
  class InvalidAdapterError < StartupError

    def initialize(message)
      super(message, ExitCodes::INVALID_ADAPTER)
    end

  end
end