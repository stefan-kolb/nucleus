module Paasal
  module API
    module Models
      # The Link describes a reference inside the API that can
      # redirect to the current resource or any other resource.
      class Link < Grape::Entity

        def self.entity_name
          'Link'
        end

        expose :href, safe: true, documentation: { desc: 'The link to the described resource', required: true, type: 'Url' }

      end
    end
  end
end