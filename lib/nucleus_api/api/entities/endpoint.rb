module Nucleus
  module API
    module Models
      class Endpoint < AbstractEntity
        # The name of the entity to be used
        def self.entity_name
          'Endpoint'
        end

        # Please do NOT inherit from the persisted entity.
        # For some strange reason the route will then not get exported, resulting in 404 responses

        expose :id, safe: true, documentation: {
          desc: 'The ID of the endpoint',
          type: String,
          required: true,
          presence: false
        }

        expose :created_at, safe: true, documentation: {
          desc: 'UTC timestamp in ISO8601 format, describes when the endpoint was created',
          type: String,
          required: true,
          presence: false
        }

        expose :updated_at, safe: true, documentation: {
          desc: 'UTC timestamp in ISO8601 format, describes when the endpoint was updated the last time',
          type: String,
          required: true,
          presence: false
        }

        expose :name, documentation: {
          type: String, desc: 'Endpoint name, e.g. \'IBM Bluemix EU-1\'',
          required: true,
          allow_blank: false
        }

        expose :url, documentation: {
          type: String, desc: 'Link to the endpoint\'s root node',
          required: true,
          allow_blank: false
        }

        expose :app_domain, documentation: {
          type: String, desc: 'Default application domain, where created apps can be accessed',
          required: false
        }

        expose :trust, documentation: {
          type: Virtus::Attribute::Boolean, desc: 'Trust the endpoint, if true the SSL certificates are not checked',
          required: true, example: false, default: false
        } do |trusted, _options|
          trusted[:trust] ? trusted[:trust] : false
        end

        expose :_links, using: ApiReferences, documentation: {
          type: 'ApiReferences', desc: 'Resource links', required: true
        } do |instance, _o|
          {
            self: { href: link_resource(%w(endpoints), instance) },
              # link back to the provider
              parent: { href: link_resource(%w(providers), instance.provider) },
              # associated applications
              applications: { href: link_child_resource(%w(endpoints), instance, %w(applications)) }, safe: true
          }
        end
      end
    end
  end
end
