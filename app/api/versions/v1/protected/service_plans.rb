module Paasal
  module API
    module V1
      class ServicePlans < Grape::API
        helpers SharedParamsHelper

        resource 'endpoints/:endpoint_id/services', desc: 'Service plans',
                 swagger: { name: 'services', nested: false } do
          params do
            use :endpoint_id
            use :service_id
          end
          # regex to allow dots in the service id as path element (as required by the Openshift V2 names)
          resource ':service_id/plans', requirements: { service_id: %r{[^\/]*} } do
            desc 'List all available plans of the service' do
              success Models::ServicePlans
              failure [[200, 'Services retrieved', Models::Services]].concat ErrorResponses.standard_responses
            end
            get '/' do
              present adapter.service_plans(params[:service_id]), with: Models::ServicePlans
            end

            desc 'Retrieve a specific plan of the service' do
              success Models::ServicePlan
              failure [[200, 'Service retrieved', Models::Service]].concat ErrorResponses.standard_responses
            end
            params do
              use :service_plan_id
            end
            # regex to allow dots in the service id as path element
            get ':service_plan_id', requirements: { service_plan_id: %r{[^\/]*} } do
              present adapter.service_plan(params[:service_id], params[:service_plan_id]), with: Models::ServicePlan
            end
          end
        end
      end
    end
  end
end
