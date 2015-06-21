module Paasal
  module API
    module Models
      class ApplicationReferences < Grape::Entity
        def self.entity_name
          'ApplicationReferences'
        end

        expose :self, documentation: { type: 'Link', desc: 'Self-reference', required: true },
               using: Paasal::API::Models::Link

        expose :parent, documentation: { type: 'Link', desc: 'Reference to endpoint the application belongs to' },
               using: Paasal::API::Models::Link, safe: true

        expose :logs,
               documentation: { type: 'Link', desc: 'Reference to the application\'s log files' },
               using: Paasal::API::Models::Link, safe: true

        expose :vars,
               documentation: { type: 'Link', desc: 'Reference to the application\'s environment variables' },
               using: Paasal::API::Models::Link, safe: true

        expose :domains,
               documentation: { type: 'Link', desc: 'Reference to the application\'s domains, also called routes' },
               using: Paasal::API::Models::Link, safe: true

        expose :services,
               documentation: { type: 'Link', desc: 'Reference to the application\'s services.' },
               using: Paasal::API::Models::Link, safe: true
      end
    end
  end
end
