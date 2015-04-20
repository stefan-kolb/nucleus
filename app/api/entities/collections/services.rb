module Paasal
  module API
    module Models
      class Services < CollectionEntity
        def self.entity_name
          'ServiceList'
        end

        item_collection('services', 'services', Models::Service)
        basic_links('endpoints/%{endpoint_id}', 'services')
      end
    end
  end
end
