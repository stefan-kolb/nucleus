module Paasal
  module API
    module Models
      class Domain < PersistedEntity
        def self.entity_name
          'Domain'
        end

        expose :name, documentation: {
          type: String, desc: 'Domain name, e.g. \'mydomain.com\'',
          required_details: { request: { POST: true, PATCH: false }, response: true }
        }

        # TODO: domain description

        expose :_links, using: Paasal::API::Models::BasicReferences, documentation: {
          type: 'References', desc: 'Resource links', is_array: true } do |instance, o|
          {
            self: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                              ['applications', instance[:application_id], 'domains', instance[:id]]) },
            # link back to the endpoint
            parent: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                                ['applications', instance[:application_id]]) }
          }
        end
      end
    end
  end
end
