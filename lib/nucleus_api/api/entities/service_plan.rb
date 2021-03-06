module Nucleus
  module API
    module Models
      class ServicePlan < PersistedEntity
        # The name of the entity to be used
        def self.entity_name
          'ServicePlan'
        end

        # all properties are read only

        expose :id, documentation: {
          type: String, desc: 'Service plan ID, e.g. \'77140bb0-957b-4005-bdc4-c39427ee0390\'',
          required: true
        }

        expose :name, documentation: {
          type: String, desc: 'Name of the plan, e.g. \'Dedicated Cluster M1\'',
          required: true
        }

        expose :free, documentation: {
          type: Virtus::Attribute::Boolean, desc: 'Is this a free plan?',
          required: true
        }

        expose :description, documentation: {
          type: String, desc: 'Description of the plan',
          required: true
        }

        expose :costs, documentation: {
          desc: 'The costs when adding this service to your application. Each cost entry must be payed for. This can '\
            'include fixed costs, e.g. to be payed per month, and usage dependent costs, e.g. to be payed per X calls',
          required: true,
          is_array: true
        }, using: ServiceCosts
      end
    end
  end
end
