module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        # cloud control application's log management operations
        module Logs
          # @see Stub#logs
          def logs(application_name_or_id)
            # TODO: implement me
          end

          # @see Stub#log?
          def log?(application_name_or_id, log_id)
            # TODO: implement me
          end

          # @see Stub#tail
          def tail(application_name_or_id, log_id, stream)
            # TODO: implement me
          end

          # @see Stub#log_entries
          def log_entries(application_name_or_id, log_id)
            # TODO: implement me
          end
        end
      end
    end
  end
end
