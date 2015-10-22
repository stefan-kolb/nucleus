module Nucleus
  module API
    module Models
      class ApiVersionResource < AbstractEntity
        expose :name, documentation: {
          type: String, desc: 'Resource name, e.g. providers'
        }

        expose :_links, using: ApiReferences, documentation: {
          type: 'ApiReferences', desc: 'Resource links', required: true } do |i, _o|
          {
            self: { href: link_resource([i[:name]]) }
          }
        end
      end
    end
  end
end
