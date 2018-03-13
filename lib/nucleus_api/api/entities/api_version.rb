module Nucleus
  module API
    module Models
      # An ApiVersion belongs to the API of our application and offers
      # multiple resources according to a defined schema.
      class ApiVersion < AbstractEntity
        expose :name, documentation: { type: String, desc: 'API version, e.g. v1 or v2' }

        expose :resources, documentation: {
          type: 'Nucleus::API::Models::VersionResource', is_array: true,
           desc: 'Resources of the API version'
        }, using: ApiVersionResource, unless: { collection: true }

        expose :_links, using: ApiReferences, documentation: {
          type: 'ApiReferences', required: true, desc: 'Resource links'
        } do |_i, _o|
          {
            self: { href: link_resource(%w[resources]) },
              # link back to the API root
              parent: { href: link_api_root },
              # link to the API version documentation
              docs: { href: link_docs }
          }
        end

        # Create a link to the documentation for this specific API version
        def link_docs
          # TODO: evaluate how to provide swagger-ui documentations for multiple API versions. Currently WIP...
          "#{link_generator.root_url}/docs"
          # "#{link_generator.root_url}/docs/api/#{object[:name]}"
        end
      end
    end
  end
end
