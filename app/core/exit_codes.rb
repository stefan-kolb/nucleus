module Paasal
  # ExitCodes describe why the application failed and was stopped.
  #
  # Codes beginning with ___ stand for ___:
  #
  # 1xx => Startup failed
  #
  module ExitCodes

    ##########################
    ### Startup Exceptions ###
    ##########################

    # Unidentified startup error
    STARTUP_ERROR = 100

    # Adapter is invalid (does not implement all required methods)
    INVALID_ADAPTER = 101

    # Malformed adapter configuration, could not grant to load all providers
    INVALID_ADAPTER_CONFIG = 102

  end
end