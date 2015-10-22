module Paasal
  module API
    module Models
      class ServicePlans < CollectionEntity
        # The name of the entity to be used
        def self.entity_name
          'ServicePlanList'
        end

        item_collection('plans', 'service plans', Models::ServicePlan)
        basic_links('endpoints/%{endpoint_id}', 'plans')
      end
    end
  end
end
