module Paasal
  module API
    module Models
      class Provider < PersistedEntity
        def self.entity_name
          'Provider'
        end

        expose :name, documentation: {
          type: String, desc: 'Provider name, e.g. \'Pivotal CF\'',
          required_details: { request: { POST: true, PATCH: false }, response: true },
          allow_blank: false }

        expose :endpoints, documentation: {
          type: 'Endpoint', is_array: true,
          desc: 'Endpoints of the provider\'s service'
        }, using: Models::Endpoint, unless: { collection: true }

        expose :_links, using: Paasal::API::Models::Links, documentation: {
          required_details: { request: false, response: true },
          type: 'References', desc: 'Resource links', is_array: true } do |instance, _o|
          {
            self: { href: link_resource(%w(providers), instance) },
              # link back to the vendor
              parent: { href: link_resource(%w(vendors), instance.vendor) },
              # associated endpoints
              endpoints: { href: link_child_resource(%w(providers), instance, %w(endpoints)) }
          }
        end
      end
    end
  end
end
