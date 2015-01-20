module Paasal
  module API
    module Models
      class Endpoints < AbstractEntity

        def self.entity_name
          'EndpointList'
        end

        present_collection true

        expose :size, documentation: {
          type: 'int', required: true, desc: 'Number of items in the \'endpoints\' collection'
        } do |status, options|
          status[:items].nil? ? 0 : status[:items].size
        end

        expose :items, as: 'endpoints', documentation: {
          type: 'Endpoint', desc: 'List of the available endpoints', is_array: true
        }, using: Models::Endpoint

        expose :_links, using: Paasal::API::Models::Links, documentation: {
          type: 'References', desc: 'Resource links', is_array: true } do |i, o|
          {
              self: { href: link_child_resource(%w(providers), o[:env]['rack.routing_args'][:provider_id], %w(endpoints)) },
              # link back to the provider
              parent: { href: link_resource(%w(providers), o[:env]['rack.routing_args'][:provider_id]) }
          }
        end

      end
    end
  end
end