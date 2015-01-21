module Paasal
  module API
    module Models
      # An ApiVersion belongs to the API of our application and offers
      # multiple resources according to a defined schema.
      class ApiVersion < AbstractEntity

        expose :name, documentation: { type: 'String', desc: 'API version, e.g. v1 or v2' }

        expose :resources,  documentation: {
           type: 'Paasal::API::Models::VersionResource', is_array: true,
           desc: 'Resources of the API version'
        }, using: Models::ApiVersionResource, unless: { collection: true }

        expose :_links, using: Paasal::API::Models::Links, documentation: {
          type: 'References', required: true, desc: 'Resource links', is_array: true } do |_i, _o|
          {
              self: { href: link_api_version },
              # link back to the API root
              parent: { href: link_api_root },
              # link to the API version documentation
              docs: { href: link_docs }
          }
        end

      end
    end
  end
end
