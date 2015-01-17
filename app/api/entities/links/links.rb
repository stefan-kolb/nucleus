module Paasal
  module API
    module Models
      class Links < Grape::Entity

        def self.entity_name
          'References'
        end

        expose :self, documentation: { type: 'Link', desc: 'Self-reference', required: true },
               using: Paasal::API::Models::Link

        expose :parent, documentation: { type: 'Link', desc: 'Reference to parent resource' },
               using: Paasal::API::Models::Link, safe: true

        expose :docs, documentation: { type: 'Link', desc: 'Documentation reference' },
               using: Paasal::API::Models::Link, safe: true

        expose :providers, documentation: { type: 'Link', desc: 'Reference to providers that belong to this resource' },
               using: Paasal::API::Models::Link, safe: true

        expose :endpoints, documentation: { type: 'Link', desc: 'Reference to endpoints that belong to this resource' },
               using: Paasal::API::Models::Link, safe: true

      end
    end
  end
end