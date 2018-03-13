module Nucleus
  module API
    module Models
      class InstalledService < AbstractService
        # The name of the entity to be used
        def self.entity_name
          'InstalledService'
        end

        # all properties are read only

        expose :id, documentation: {
          type: String, desc: 'Installed service ID, e.g. \'77140bb0-957b-4005-bdc4-c39427ee0390\'. Must not '\
            '(but can) be equal to the ID of the service this installation is based on',
          required: true
        }

        expose :active_plan, documentation: {
          type: String, desc: 'Name of the chosen and currently active plan',
          required: true
        }

        expose :web_url, documentation: {
          type: String, desc: 'URL to the interface of the installed service',
          required: true
        }

        expose :properties, documentation: {
          desc: 'Properties of the installed service, e.g. environment variables or configuration',
          required: true,
          is_array: true
        }, using: InstalledServiceProperty

        expose :_links, using: BasicReferences, documentation: {
          type: 'BasicReferences', desc: 'Resource links', required: true
        } do |instance, o|
          {
            self: { href: link_child_resource(%w[endpoints], o[:env]['rack.routing_args'][:endpoint_id],
                                              ['services', instance[:id]]) },
            plans: { href: link_child_resource(%w[endpoints], o[:env]['rack.routing_args'][:endpoint_id],
                                               ['services', instance[:id], 'plans']) },
            # link back to the application
            parent: { href: link_child_resource(%w[endpoints], o[:env]['rack.routing_args'][:endpoint_id],
                                                ['applications', o[:env]['rack.routing_args'][:application_id]]) }
          }
        end
      end
    end
  end
end
