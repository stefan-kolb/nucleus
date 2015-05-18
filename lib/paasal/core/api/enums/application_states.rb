module Paasal
  module API
    module Enums
      # All states that an application can obtain according to the lifecycle of PaaSal apps.
      module ApplicationStates
        # Application is created, no data has been deployed yet to any of the instances.
        CREATED = :created
        # Application crashed, none of the instances is running.
        # here was an error while starting or running the application-
        CRASHED  = :crashed
        # All instances of the application were idled by the platform.
        IDLE = :idle
        # At least one instance of the application is running.
        RUNNING  = :running
        # All instances of the already deployed application are stopped.
        STOPPED  = :stopped
        # The application data has been deployed, but the application was not started yet. No instance is running.
        DEPLOYED = :deployed

        # List all application states.
        # @return [Array<Symbol>] Symbols representing an application state
        def self.all
          constants
        end
      end
    end
  end
end
