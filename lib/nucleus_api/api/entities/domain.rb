module Nucleus
  module API
    module Models
      class Domain < PersistedEntity
        # The name of the entity to be used
        def self.entity_name
          'Domain'
        end

        expose :name, documentation: {
          type: String, desc: 'FQDN of the domain name, e.g. \'mydomain.com\'',
          required: true
        }

        expose :_links, using: Nucleus::API::Models::BasicReferences, documentation: {
          type: 'BasicReferences', desc: 'Resource links', required: true
        } do |instance, o|
          {
            self: { href: link_child_resource(%w[endpoints], o[:env]['rack.routing_args'][:endpoint_id],
                                              ['applications', o[:env]['rack.routing_args'][:application_id],
                                               'domains', instance[:id]]) },
            # link back to the application
            parent: { href: link_child_resource(%w[endpoints], o[:env]['rack.routing_args'][:endpoint_id],
                                                ['applications', o[:env]['rack.routing_args'][:application_id]]) }
          }
        end
      end
    end
  end
end
