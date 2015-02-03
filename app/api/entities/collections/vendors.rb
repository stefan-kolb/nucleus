module Paasal
  module API
    module Models
      class Vendors < CollectionEntity
        def self.entity_name
          'VendorList'
        end

        item_collection('vendors', 'vendors', Models::Vendor)
        basic_links('', 'vendors')
      end
    end
  end
end
