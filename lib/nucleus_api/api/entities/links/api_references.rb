module Nucleus
  module API
    module Models
      class ApiReferences < Grape::Entity
        def self.entity_name
          'ApiReferences'
        end

        expose :self, documentation: { type: 'Link', desc: 'Self-reference', required: true },
               using: Nucleus::API::Models::Link

        expose :parent, documentation: { type: 'Link', desc: 'Reference to parent resource' },
               using: Nucleus::API::Models::Link, safe: true

        expose :docs, documentation: { type: 'Link', desc: 'Documentation reference' },
               using: Nucleus::API::Models::Link, safe: true

        expose :providers,
               documentation: { type: 'Link', desc: 'Reference to providers that belong to this resource' },
               using: Nucleus::API::Models::Link, safe: true

        expose :endpoints,
               documentation: { type: 'Link', desc: 'Reference to endpoints that belong to this resource' },
               using: Nucleus::API::Models::Link, safe: true

        expose :applications,
               documentation: { type: 'Link', desc: 'Reference to applications that belong to this resource' },
               using: Nucleus::API::Models::Link, safe: true
      end
    end
  end
end
