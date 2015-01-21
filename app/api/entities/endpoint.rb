module Paasal
  module API
    module Models
      class Endpoint < PersistedEntity
        def self.entity_name
          'Endpoint'
        end

        expose :name, documentation: {
          type: 'String', desc: 'Endpoint name, e.g. \'IBM Bluemix EU-1\''
        }

        expose :data do
          expose :url, documentation: {
            type: 'String', desc: 'Link to the endpoint\'s root node'
          }
        end

        expose :_links, using: Paasal::API::Models::Links, documentation: {
          type: 'References', desc: 'Resource links', is_array: true } do |instance, _o|
          {
              self: { href: link_resource(%w(endpoints), instance) },
              # link back to the provider
              parent: { href: link_resource(%w(providers), instance.provider) },
              # TODO is only available when authenticated
              # associated applications
              applications: { href: link_child_resource(%w(endpoints), instance, %w(applications)) }, safe: true
          }
        end
      end
    end
  end
end
