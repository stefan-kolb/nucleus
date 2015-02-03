module Paasal
  module API
    module Models
      class Domains < CollectionEntity
        def self.entity_name
          'DomainList'
        end
        item_collection('domains', 'domains', Models::Domain)
        basic_links('endpoints/%{:endpoint_id}/applications/%{:application_id}', 'domains')
      end
    end
  end
end
