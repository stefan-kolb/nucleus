module Paasal
  module API
    module Models
      class Providers < CollectionEntity
        def self.entity_name
          'ProviderList'
        end

        item_collection('providers', 'providers', Models::Provider)
        basic_links('vendors/%{vendor_id}', 'providers')
      end
    end
  end
end
