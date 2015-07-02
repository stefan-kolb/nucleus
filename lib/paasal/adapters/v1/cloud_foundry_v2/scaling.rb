module Paasal
  module Adapters
    module V1
      class CloudFoundryV2 < Stub
        module Scaling
          # @see Stub#scale
          def scale(application_name_or_id, instances)
            # update the number of instances on the application
            update_application(application_name_or_id, instances: instances)
          end
        end
      end
    end
  end
end
