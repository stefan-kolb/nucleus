module Nucleus
  module API
    module V1
      class Services < Grape::API
        helpers SharedParamsHelper

        resource 'endpoints/:endpoint_id/services', desc: 'Endpoint\'s services that can be bound to applications',
                 swagger: { name: 'services', nested: false } do
          desc 'Get all services that are available at the endpoint' do
            success Models::Services
            failure ErrorResponses.standard_responses
          end
          params do
            use :endpoint_id
          end
          get '/' do
            present adapter.services, with: Models::Services
          end

          desc 'Retrieve a specific service of the endpoint' do
            success Models::Services
            failure ErrorResponses.standard_responses
          end
          params do
            use :endpoint_id
            use :service_id
          end
          # regex to allow dots in the service id as path element (as required by the Openshift V2 names)
          get ':service_id', requirements: { service_id: %r{[^\/]*} } do
            present adapter.service(params[:service_id]), with: Models::Service
          end
        end
      end
    end
  end
end
