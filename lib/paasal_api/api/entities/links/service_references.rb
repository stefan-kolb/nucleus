module Paasal
  module API
    module Models
      class ServiceReferences < Grape::Entity
        def self.entity_name
          'ServiceReferences'
        end

        expose :self, documentation: { type: 'Link', desc: 'Self-reference', required: true },
               using: Paasal::API::Models::Link

        expose :parent, documentation: { type: 'Link', desc: 'Reference to endpoint the service belongs to' },
               using: Paasal::API::Models::Link, safe: true

        expose :plans, documentation: { type: 'Link', desc: 'Reference to the service\'s plans' },
               using: Paasal::API::Models::Link, safe: true
      end
    end
  end
end
