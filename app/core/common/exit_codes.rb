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
  end
end
