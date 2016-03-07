module Nucleus
  module Adapters
    module V1
      class Heroku < Stub
        module Regions
          # @see Stub#regions
          def regions
            response = get('/regions').body
            response.each do |region|
              region[:id] = region.delete(:name).upcase
            end
            response
          end

          # @see Stub#region
          def region(region_name)
            found_region = native_region(region_name)
            raise Errors::AdapterResourceNotFoundError,
                  "Region '#{region_name}' does not exist at the endpoint" if found_region.nil?
            found_region[:id] = found_region.delete(:name).upcase
            found_region
          end

          private

          def retrieve_region(application)
            return unless application.key?(:region)
            found_region = native_region(application[:region])
            raise Errors::SemanticAdapterRequestError,
                  "Region '#{application[:region]}' does not exist at the endpoint" if found_region.nil?
            application[:region] = found_region[:id]
          end

          def native_region(region_name)
            response = get('/regions').body
            response.find { |region| region[:name].casecmp(region_name) == 0 }
          end
        end
      end
    end
  end
end
