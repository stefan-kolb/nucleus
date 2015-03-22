module Paasal
  module API
    module Application
      module LogfileType
        API = :api
        APPLICATION = :application
        # information about the build process
        BUILD = :build
        ERROR = :error
        # none of the other states
        OTHER = :other
        REQUEST = :request
        SYSTEM = :system

        # List all types of log files.
        # @return [Array<Symbol>] Symbols representing a log file type
        def self.all
          constants
        end
      end
    end
  end
end
