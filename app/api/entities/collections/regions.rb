module Paasal
  module API
    module Models
      class Regions < CollectionEntity
        def self.entity_name
          'RegionList'
        end

        item_collection('regions', 'regions', Models::Region)
        basic_links('endpoints/%{endpoint_id}', 'regions')
      end
    end
  end
end
