module Paasal
  module API
    module Models
      class Applications < CollectionEntity
        # The name of the entity to be used
        def self.entity_name
          'ApplicationList'
        end

        item_collection('applications', 'applications', Models::Application)
        basic_links('endpoints/%{endpoint_id}', 'applications')
      end
    end
  end
end
