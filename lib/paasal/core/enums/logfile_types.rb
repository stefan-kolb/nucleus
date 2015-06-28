module Paasal
  module Enums
    # All types of logs that are distinguished by PaaSal.
    module ApplicationLogfileType
      # The API log aggregates all messages that changed the application state, e.g. updating an application.
      API = :api
      # The application log includes all messages of the application itself
      APPLICATION = :application
      # The build log shows the information of the recent build process(es).
      BUILD = :build
      # The error log shows all logged error messages
      ERROR = :error
      # All logs marked as +other+ can't be assigned to any of the other states
      OTHER = :other
      # The request log shows all requests that were made to the application
      REQUEST = :request
      # System logs aggregate all system relevant outputs,
      # e.g. calling lifecycle operations on application instances
      SYSTEM = :system

      # List all types of log files.
      # @return [Array<Symbol>] Symbols representing a log file type
      def self.all
        constants
      end
    end
  end
end
