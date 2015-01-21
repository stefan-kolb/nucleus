module Paasal
  module API
    module Models
      class Vendor < PersistedEntity

        def self.entity_name
          'Vendor'
        end

        expose :name, documentation: { type: 'String', desc: 'Vendor name, e.g. \'Cloud Foundry\'' }

        expose :key, documentation: { type: 'String', desc: 'Vendor key, e.g. \'cloud-foundry\'' }

        expose :providers, documentation: {
          type: 'Paasal::API::Models::Provider',
          is_array: true,
          desc: 'Providers that use this vendor\'s product'
        }, using: Models::Provider, unless: { collection: true }

        expose :_links, using: Paasal::API::Models::Links, documentation: {
          type: 'References', desc: 'Resource links', is_array: true } do |instance, _o|
          {
              self: { href: link_resource(%w(vendors), instance) },
              # link back to the api version
              parent: { href: link_resource },
              # associated providers
              providers: { href: link_child_resource(%w(vendors), instance, %w(providers)) }
          }
        end

      end
    end
  end
end