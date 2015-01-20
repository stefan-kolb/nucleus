module Paasal
  module API
    module Models
      class Vendors < AbstractEntity

        def self.entity_name
          'VendorList'
        end

        present_collection true

        expose :size, documentation: {
          type: 'int', required: true, desc: 'Number of items in the \'vendors\' collection'
        } do |status, options|
          status[:items].nil? ? 0 : status[:items].size
        end

        expose :items, as: 'vendors', using: Paasal::API::Models::Vendor, documentation: {
          type: 'Vendor', required: true, desc: 'List of the available vendors', is_array: true
        }

        expose :_links, using: Paasal::API::Models::Links, documentation: {
          type: 'References', required: true, desc: 'Resource links', is_array: true } do |i, o|
          {
              self: { href: link_resource(%w(vendors)) },
              # link back to the api version
              parent: { href: link_api_version }
          }
        end

      end
    end
  end
end