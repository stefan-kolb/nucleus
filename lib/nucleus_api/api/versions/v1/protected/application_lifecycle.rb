module Nucleus
  module API
    module V1
      class ApplicationLifecycle < Grape::API
        helpers SharedParamsHelper

        params do
          use :application_context
        end
        resource 'endpoints/:endpoint_id/applications/:application_id/actions', desc: 'Lifecycle & scaling',
                  swagger: { nested: false, name: 'application-actions' } do
          desc 'Start the application' do
            success Models::Application
            failure [[200, 'Application start triggered',
                      Models::Application]].concat ErrorResponses.standard_responses
          end
          post '/start' do
            present adapter.start(params[:application_id]), with: Models::Application
            status 200
          end

          desc 'Stop the application' do
            success Models::Application
            failure [[200, 'Application stop triggered',
                      Models::Application]].concat ErrorResponses.standard_responses
          end
          post '/stop' do
            present adapter.stop(params[:application_id]), with: Models::Application
            status 200
          end

          desc 'Restart the application' do
            success Models::Application
            failure [[200, 'Application restart triggered',
                      Models::Application]].concat ErrorResponses.standard_responses
          end
          post '/restart' do
            present adapter.restart(params[:application_id]), with: Models::Application
            status 200
          end
        end # end of resource
      end
    end
  end
end
