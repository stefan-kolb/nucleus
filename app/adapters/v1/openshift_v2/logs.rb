module Paasal
  module Adapters
    module V1
      class OpenshiftV2 < Stub
        module Logs
          def logs(application_name_or_id)
            # TODO: implement me
          end

          def log?(application_name_or_id, log_id)
            # TODO: implement me
          end

          def tail(application_name_or_id, log_id, stream)
            # TODO: implement me
          end

          def log_entries(application_name_or_id, log_id)
            # TODO: implement me
          end
        end
      end
    end
  end
end
