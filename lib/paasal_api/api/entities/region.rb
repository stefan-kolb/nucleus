module Paasal
  module API
    module Models
      class Region < PersistedEntity
        # The name of the entity to be used
        def self.entity_name
          'Region'
        end

        expose :id, documentation: {
          type: String, desc: 'Region name and identifier, e.g. \'EU\' or \'US\'',
          required: true
        }

        expose :description, documentation: {
          type: String, desc: 'Region description, restrictions, etc.',
          required: true
        }

        expose :_links, using: BasicReferences, documentation: {
          type: 'BasicReferences', desc: 'Resource links', required: true } do |instance, o|
          {
            self: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                              ['regions', instance[:id]]) },
            # link back to the endpoint
            parent: { href: link_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id]) }
          }
        end
      end
    end
  end
end
