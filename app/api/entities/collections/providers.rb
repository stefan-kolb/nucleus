module Paasal
  module API
    module Models
      class Providers < AbstractEntity
        def self.entity_name
          'ProviderList'
        end

        present_collection true

        expose :size, documentation: {
          type: 'int', required: true, desc: 'Number of items in the \'providers\' collection'
        } do |instance, _o|
          instance[:items].nil? ? 0 : instance[:items].size
        end

        expose :items, as: 'providers', documentation: {
          type: 'Provider', desc: 'List of the available providers', is_array: true
        }, using: Models::Provider

        expose :_links, using: Paasal::API::Models::Links, documentation: {
          type: 'References', desc: 'Resource links', is_array: true } do |_i, o|
          {
            self: { href: link_child_resource(%w(vendors), o[:env]['rack.routing_args'][:vendor_id], %w(providers)) },
            # link back to the vendor
            parent: { href: link_resource(%w(vendors), o[:env]['rack.routing_args'][:vendor_id]) }
          }
        end
      end
    end
  end
end
