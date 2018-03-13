module Nucleus
  module Adapters
    module V1
      class CloudFoundryV2 < Stub
        module Regions
          # @see Stub#regions
          def regions
            [default_region]
          end

          # @see Stub#region
          def region(region_name)
            raise Errors::AdapterResourceNotFoundError, "Region '#{region_name}' does not exist at the endpoint" unless region_name.casecmp('default').zero?
            default_region
          end

          private

          def default_region
            {
              id: 'default',
              description: 'Default region, Cloud Foundry does not support multi regions yet.',
              created_at: Time.at(0).to_datetime,
              updated_at: Time.at(0).to_datetime
            }
          end
        end
      end
    end
  end
end
