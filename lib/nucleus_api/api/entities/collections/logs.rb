module Nucleus
  module API
    module Models
      class Logs < CollectionEntity
        # The name of the entity to be used
        def self.entity_name
          'LogList'
        end

        item_collection('logs', 'logs', Models::Log)
        basic_links('endpoints/%{endpoint_id}/applications/%{application_id}', 'logs')
      end
    end
  end
end
