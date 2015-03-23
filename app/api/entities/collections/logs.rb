module Paasal
  module API
    module Models
      class Logs < CollectionEntity
        def self.entity_name
          'LogList'
        end

        item_collection('logs', 'logs', Models::Log)
        basic_links('endpoints/%{endpoint_id}/applications/%{application_id}', 'logs')
      end
    end
  end
end
