module Paasal
  module API
    module Application
      module States
        RUNNING  = :running
        STOPPED  = :stopped
        DEPLOYED = :deployed

        STARTING = :starting
        STOPPING = :stopping

        # List all application states.
        # @return [Array<Symbol>] Symbols representing an application state
        def self.all
          constants
        end
      end
    end
  end
end
