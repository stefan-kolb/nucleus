module Paasal
  module API
    module Models
      class Region < PersistedEntity
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

        expose :_links, using: Paasal::API::Models::ApplicationLinks, documentation: {
          type: 'RegionReferences', desc: 'Resource links', is_array: true } do |instance, o|
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
