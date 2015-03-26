module Paasal
  module API
    module Application
      module States
        CREATED = :created
        CRASHED  = :crashed
        IDLE = :idle
        RUNNING  = :running
        STOPPED  = :stopped
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
