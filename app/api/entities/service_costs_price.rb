module Paasal
  module API
    module Models
      class ServiceCostsPrice < Grape::Entity
        def self.entity_name
          'ServiceCostsPrice'
        end

        # all properties are read only

        expose :currency, documentation: {
          type: String, desc: 'Currency of the price',
          required_details: { request: false, response: true }
        }

        expose :amount, documentation: {
          type: Float, desc: 'Amount that has to be paid per period in the specified currency',
          required_details: { request: false, response: true }
        }
      end
    end
  end
end
