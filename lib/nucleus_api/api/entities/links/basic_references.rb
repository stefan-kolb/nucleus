module Nucleus
  module API
    module Models
      class BasicReferences < Grape::Entity
        def self.entity_name
          'BasicReferences'
        end

        expose :self, documentation: { type: 'Link', desc: 'Self-reference', required: true },
               using: Nucleus::API::Models::Link

        expose :parent, documentation: { type: 'Link', desc: 'Reference to parent resource', required: true },
               using: Nucleus::API::Models::Link
      end
    end
  end
end
