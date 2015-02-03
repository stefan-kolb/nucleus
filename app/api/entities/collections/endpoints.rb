module Paasal
  module API
    module Models
      class Endpoints < CollectionEntity
        def self.entity_name
          'EndpointList'
        end

        item_collection('endpoints', 'endpoints', Models::Endpoint)
        basic_links('providers/%{provider_id}', 'endpoints')
      end
    end
  end
end
