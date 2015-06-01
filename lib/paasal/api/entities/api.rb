module Paasal
  module API
    module Models
      # The Api is the root node of our API.
      class Api < AbstractEntity
        expose :versions,  documentation: {
          type: 'Paasal::API::Version', is_array: true,
          desc: 'List of available API versions'
        }, using: ApiVersion

        expose :_links, using: Links, documentation: {
          type: 'References', required: true, desc: 'Resource links' } do |_i, _o|
          {
            self: { href: link_api_root },
              # link to the API documentation
              docs: { href: link_docs }
          }
        end
      end
    end
  end
end
