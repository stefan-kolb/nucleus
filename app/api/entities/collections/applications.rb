module Paasal
  module API
    module Models
      class Applications < AbstractEntity

        def self.entity_name
          'ApplicationList'
        end

        present_collection true

        expose :size, documentation: {
          type: 'int', required: true, desc: 'Number of items in the \'applications\' collection'
        } do |instance, _o|
          instance[:items].nil? ? 0 : instance[:items].size
        end

        expose :items, as: 'applications', documentation: {
          type: 'Application', desc: 'List of created applications', is_array: true
        }, using: Models::Application

        expose :_links, using: Paasal::API::Models::Links, documentation: {
          type: 'References', desc: 'Resource links', is_array: true } do |_i, o|
          {
              self: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id], %w(applications)) },
              # link back to the endpoint
              parent: { href: link_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id]) }
          }
        end

      end
    end
  end
end