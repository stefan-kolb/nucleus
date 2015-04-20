module Paasal
  module API
    module Models
      class InstalledServices < CollectionEntity
        def self.entity_name
          'InstalledServiceList'
        end

        item_collection('services', 'services', Models::Service)
        basic_links('endpoints/%{endpoint_id}/applications/%{application_id}', 'services')
      end
    end
  end
end
