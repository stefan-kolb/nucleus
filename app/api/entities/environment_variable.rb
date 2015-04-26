module Paasal
  module API
    module Models
      class EnvironmentVariable < AbstractEntity
        def self.entity_name
          'EnvironmentVariable'
        end

        expose :id, documentation: {
          type: String, desc: 'Variable identifier, unique per application',
          required: true
        }

        expose :key, documentation: {
          type: String, desc: 'Variable key, e.g. \'RAILS_ENV\'',
          required: true
        }

        expose :value, documentation: {
          type: String, desc: 'Variable value, e.g. \'development\'',
          required: true
        }

        expose :_links, using: Paasal::API::Models::BasicReferences, documentation: {
          type: 'BasicReferences', desc: 'Resource links', is_array: true } do |instance, o|
          {
            self: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                              ['applications', o[:env]['rack.routing_args'][:application_id],
                                               'vars', instance[:id]]) },
            # link back to the application
            parent: { href: link_child_resource(%w(endpoints), o[:env]['rack.routing_args'][:endpoint_id],
                                                ['applications', o[:env]['rack.routing_args'][:application_id]]) }
          }
        end
      end
    end
  end
end
