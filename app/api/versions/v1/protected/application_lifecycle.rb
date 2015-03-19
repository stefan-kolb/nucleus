module Paasal
  module API
    module V1
      class ApplicationLifecycle < Grape::API
        helpers Paasal::SharedParamsHelper

        params do
          use :application_context
        end
        resource 'endpoints/:endpoint_id/applications/:application_id/actions', desc: 'Application actions',
                  swagger: { nested: false, name: 'application-actions' } do
          desc 'Start the application' do
            success Models::Application
            failure [[200, 'Application start triggered',
                      Models::Application]].concat ErrorResponses.standard_responses
          end
          post '/start' do
            application = with_authentication { adapter.start(params[:application_id]) }
            present application, with: Models::Application
          end

          desc 'Stop the application' do
            success Models::Application
            failure [[200, 'Application stop triggered',
                      Models::Application]].concat ErrorResponses.standard_responses
          end
          post '/stop' do
            application = with_authentication { adapter.stop(params[:application_id]) }
            present application, with: Models::Application
          end

          desc 'Restart the application' do
            success Models::Application
            failure [[200, 'Application restart triggered',
                      Models::Application]].concat ErrorResponses.standard_responses
          end
          post '/restart' do
            application = with_authentication { adapter.restart(params[:application_id]) }
            present application, with: Models::Application
          end
        end # end of resource
      end
    end
  end
end
