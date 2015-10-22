module Nucleus
  module API
    module Models
      class ServiceCosts < Grape::Entity
        # The name of the entity to be used
        def self.entity_name
          'ServiceCosts'
        end

        # all properties are read only

        expose :period, documentation: {
          type: String, desc: 'Period for which the price has to be payed, e.g. \'hour\' or \'month\'',
          required: true
        }

        expose :per_instance, documentation: {
          type: Virtus::Attribute::Boolean, desc: 'Does the fee have to be paid per application instance. This does '\
            'NOT refer to possible instances of the service itself.',
          required: true
        }

        expose :price, documentation: {
          desc: 'Price that has to be paid per period, listed in the available currencies',
          required: true,
          is_array: true
        }, using: ServiceCostsPrice
      end
    end
  end
end
