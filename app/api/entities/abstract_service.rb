module Paasal
  module API
    module Models
      class AbstractService < PersistedEntity
        def self.entity_name
          'AbstractService'
        end

        # all properties are read only

        expose :name, documentation: {
          type: String, desc: 'Name of the service, e.g. \'mysql\'',
          required_details: { request: false, response: true }
        }

        expose :free_plan, documentation: {
          type: Virtus::Attribute::Boolean, desc: 'Does the service offer a free plan?',
          required_details: { request: false, response: true }
        }

        expose :description, documentation: {
          type: String, desc: 'Description of the services functionality, options and configuration',
          required_details: { request: false, response: true }
        }

        expose :release, documentation: {
          type: String, desc: 'Service release information, e.g. \'1.0.0\' or \'beta\'',
          required_details: { request: false, response: true }
        }

        expose :documentation_url, documentation: {
          type: String, desc: 'URL to further documentation of the service',
          required_details: { request: false, response: true }
        }

        expose :required_services, documentation: {
          type: String, desc: 'A complete list of services that are also required when using this service by their IDs',
          required_details: { request: false, response: true },
          is_array: true
        }
      end
    end
  end
end