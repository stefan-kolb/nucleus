module Paasal
  module Adapters
    module V1
      class OpenshiftV2 < Stub
        module Regions
          # @see Stub#regions
          def regions
            response = get('/regions').body[:data]
            response.each { |region| to_paasal_region(region) }
            # filter all non-available regions
            response.delete_if { |region| region[:allow_selection] == false }
            response
          end

          # @see Stub#region
          def region(region_name)
            region = convert_region(region_name)
            fail Errors::AdapterResourceNotFoundError,
                 "Region '#{region_name}' does not exist at the endpoint" if region.nil?
            region
          end

          private

          # Retrieve a native region for the abstracted ID and assign its name to the application entity
          def retrieve_region(application)
            return unless application.key?(:region)
            found_region = native_region(application[:region])
            fail Errors::SemanticAdapterRequestError,
                 "Region '#{application[:region]}' does not exist at the endpoint" if found_region.nil?
            application[:region] = found_region[:name]
          end

          def convert_region(region_name)
            found_region = native_region(region_name)
            found_region = to_paasal_region(found_region) unless found_region.nil?
            found_region
          end

          def native_region(region_name)
            response = get('/regions').body[:data]
            response.delete_if { |region| region[:allow_selection] == false }
            response.find { |region| parse_region_name(region[:name]).casecmp(region_name) == 0 }
          end
        end
      end
    end
  end
end
