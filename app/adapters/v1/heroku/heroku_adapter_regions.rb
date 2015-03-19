module Paasal
  module Adapters
    module V1
      module HerokuAdapterRegions
        def regions
          response = get('/regions').body
          response.each do |region|
            region[:id] = region.delete(:name).upcase
          end
          response
        end

        def region(region_name)
          found_region = native_region(region_name)
          fail Errors::AdapterResourceNotFoundError,
               "Region '#{region_name}' does not exist at the endpoint" if found_region.nil?
          found_region[:id] = found_region.delete(:name).upcase
          found_region
        end

        def retrieve_region(application)
          return unless application.key?(:region)
          found_region = native_region(application[:region])
          fail Errors::PlatformSpecificSemanticError,
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
