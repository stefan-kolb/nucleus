module Paasal
  module API
    module Models
      class Service < AbstractService
        def self.entity_name
          'Service'
        end

        # all properties are read only

        expose :id, documentation: {
          type: String, desc: 'Service ID, e.g. \'77140bb0-957b-4005-bdc4-c39427ee0390\'',
          required_details: { request: true, response: true }
        }

        expose :_links, using: BasicReferences, documentation: {
          type: 'BasicReferences', desc: 'Resource links', is_array: true } do |instance, o|
          {
            self: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                              ['services', instance[:id]]) },
            plans: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                               ['services', instance[:id], 'plans']) },
            # link back to the endpoint
            parent: { href: link_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id]) }
          }
        end
      end
    end
  end
end
