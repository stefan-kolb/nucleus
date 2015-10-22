module Nucleus
  module API
    module Models
      class Endpoints < CollectionEntity
        # The name of the entity to be used
        def self.entity_name
          'EndpointList'
        end

        item_collection('endpoints', 'endpoints', Models::Endpoint)
        basic_links('providers/%{provider_id}', 'endpoints')
      end
    end
  end
end
