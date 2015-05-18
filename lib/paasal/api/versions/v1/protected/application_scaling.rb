module Paasal
  module API
    module V1
      class ApplicationScaling < Grape::API
        helpers SharedParamsHelper

        params do
          use :application_context
        end
        resource 'endpoints/:endpoint_id/applications/:application_id/actions',  desc: 'Lifecycle & scaling',
                 swagger: { nested: false, name: 'application-actions' } do
          desc 'Scale the application' do
            success Models::Application
            failure [[200, 'Application scaled', Models::Application]].concat ErrorResponses.standard_responses
          end
          params do
            requires :instances, desc: 'Number of application instances to deploy', type: Integer, values: 1..999
          end
          post '/scale' do
            # TODO: enrich with scale-up and scale-down parameters
            present adapter.scale(params[:application_id], params[:instances]), with: Models::Application
          end
        end # end of resource
      end
    end
  end
end
