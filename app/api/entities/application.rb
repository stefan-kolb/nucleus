module Paasal
  module API
    module Models
      class Application < PersistedEntity
        def self.entity_name
          'Application'
        end

        expose :name, documentation: {
          type: 'String', desc: 'Application name, e.g. \'murmuring-shelf-1234\''
        }

        # expose :data do
        #   expose :url, documentation: {
        #     type: 'String', desc: 'Link to the endpoint\'s root node'
        #   }
        # end

        expose :_links, using: Paasal::API::Models::Links, documentation: {
          type: 'References', desc: 'Resource links', is_array: true } do |instance, o|
          {
              self: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                                ['applications', instance[:id]]) },
              # link back to the provider
              parent: { href: link_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id]) }
          }
        end
      end
    end
  end
end
