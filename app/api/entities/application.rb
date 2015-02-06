module Paasal
  module API
    module Models
      class Application < PersistedEntity
        def self.entity_name
          'Application'
        end

        expose :name, documentation: {
          type: String, desc: 'Application name, e.g. \'murmuring-shelf-1234\'',
          required_details: { request: { POST: true, PATCH: false }, response: true }
        }
        expose :id, documentation: {
          type: String, desc: 'Application ID, unique per endpoint, e.g. \'75ab5de0-b323-4607-9d6a-ca6e83ff1312\'',
          required_details: { request: false, response: true }
        }

        # TODO: runtime: Node.js, ? ? ?
        # TODO: region

        expose :autoscaled, documentation: {
          # TODO: handle boolean properly
          type: Virtus::Attribute::Boolean, desc: 'Application auto-scaling: true if enabled, otherwise false',
          required_details: { request: false, response: true }
        }

        expose :state, documentation: {
          type: String, desc: 'The application\'s state',
          values: Paasal::API::Application::States.all,
          required_details: { request: false, response: true }
        }

        expose :_links, using: Paasal::API::Models::ApplicationLinks, documentation: {
          type: 'ApplicationReferences', desc: 'Resource links', is_array: true } do |instance, o|
          {
            self: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                              ['applications', instance[:id]]) },
            # link back to the endpoint
            parent: { href: link_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id]) },
            domains: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                                 ['applications', instance[:id], 'domains']) },
            logs: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                                               ['applications', instance[:id], 'logs']) },
            vars: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                                               ['applications', instance[:id], 'vars']) }
          }
        end
      end
    end
  end
end
