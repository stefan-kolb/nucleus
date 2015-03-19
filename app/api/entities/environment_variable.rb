module Paasal
  module API
    module Models
      class EnvironmentVariable < AbstractEntity
        def self.entity_name
          'EnvironmentVariable'
        end

        expose :id, documentation: {
          type: String, desc: 'Variable identifier, unique per application',
          required_details: { request: { POST: false, PATCH: false }, response: true }
        }

        expose :key, documentation: {
          type: String, desc: 'Variable key, e.g. \'contact_email\'',
          required_details: { request: { POST: true }, response: true }
        }

        expose :value, documentation: {
          type: String, desc: 'Variable value, e.g. \'contact@mydomain.com\'',
          required_details: { request: { POST: true }, response: true }
        }

        expose :_links, using: Paasal::API::Models::BasicReferences, documentation: {
          type: 'BasicReferences', desc: 'Resource links', is_array: true } do |instance, o|
          {
            self: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                              ['applications', instance[:application_id], 'vars', instance[:id]]) },
            # link back to the application
            parent: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                                ['applications', instance[:application_id]]) }
          }
        end
      end
    end
  end
end
