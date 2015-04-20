module Paasal
  module API
    module Models
      class InstalledServiceProperty < Grape::Entity
        def self.entity_name
          'InstalledServiceProperty'
        end

        # all properties are read only

        expose :key, documentation: {
          type: String, desc: 'Name of the property, e.g. \'database_name\'',
          required_details: { request: false, response: true }
        }

        expose :value, documentation: {
          type: String, desc: 'Value of the property, e.g. \'myapp_db_1\'',
          required_details: { request: false, response: true }
        }

        expose :description, documentation: {
          type: String, desc: 'A rather short description of the property',
          required_details: { request: false, response: true }
        }
      end
    end
  end
end
