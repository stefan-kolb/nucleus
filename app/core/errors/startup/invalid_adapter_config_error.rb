module Paasal
  class InvalidAdapterConfigError < StartupError
    def initialize(message)
      super(message, ExitCodes::INVALID_ADAPTER_CONFIG)
    end
  end
end
