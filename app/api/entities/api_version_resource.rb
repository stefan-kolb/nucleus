module Paasal
  module API
    module Models
      class ApiVersionResource < AbstractEntity
        expose :name, documentation: {
          type: String, desc: 'Resource name, e.g. providers'
        }

        expose :_links, using: Paasal::API::Models::Links, documentation: {
          type: 'References', required: true, desc: 'Resource links', is_array: true } do |i, _o|
          {
            self: { href: link_resource([i[:name]]) }
          }
        end
      end
    end
  end
end
