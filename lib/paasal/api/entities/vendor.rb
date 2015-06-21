module Paasal
  module API
    module Models
      class Vendor < PersistedEntity
        # The name of the entity to be used
        def self.entity_name
          'Vendor'
        end

        expose :name, documentation: {
          type: String, desc: 'Vendor name, e.g. \'Cloud Foundry\'',
          required: true,
          allow_blank: false }

        expose :providers, documentation: {
          type: 'Provider',
          is_array: true,
          desc: 'Providers that use this vendor\'s product'
        }, using: Models::Provider, unless: { collection: true }

        expose :_links, using: ApiReferences, documentation: {
          required: true,
          type: 'ApiReferences', desc: 'Resource links', required: true } do |instance, _o|
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
