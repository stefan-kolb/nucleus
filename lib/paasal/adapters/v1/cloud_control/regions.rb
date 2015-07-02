module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        module Regions
          # @see Stub#regions
          def regions
            [default_region]
          end

          # @see Stub#region
          def region(region_name)
            fail Errors::AdapterResourceNotFoundError,
                 "Region '#{region_name}' does not exist at the endpoint" unless region_name.casecmp('default') == 0
            default_region
          end

          private

          def default_region
            {
              id: 'default',
              description: 'Default region, cloudControl does not support multi regions yet.',
              created_at: Time.at(0).to_datetime,
              updated_at: Time.at(0).to_datetime
            }
          end
        end
      end
    end
  end
end
