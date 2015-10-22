module Nucleus
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

    # Custom SSH key was specified in the options but could not be loaded
    INVALID_SSH_KEY_FILE = 101

    # Invalid key, invalid or not of format ssh-rsa OpenSSH
    INVALID_SSH_KEY = 102

    # Invalid private key, we can only accept private keys without a passphrase
    INVALID_SSH_KEY_FILE_PROTECTED = 103
  end
end
