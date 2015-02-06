module Paasal
  module API
    module V1
      module EnvVars
        class List < Grape::API
          helpers Paasal::SharedParamsHelper

          resource :endpoints do
            desc 'List of the application\'s environment variables' do
              success Models::EnvironmentVariables
              failure [[200, 'Environment variables retrieved',
                        Models::EnvironmentVariables]].concat ErrorResponses.standard_responses
            end
            params do
              use :application_context
            end
            get ':endpoint_id/applications/:application_id/vars' do
              domains = with_authentication { adapter.env_vars(params[:application_id]) }
              present domains, with: Models::Domains
            end
          end #end of resource
        end
      end
    end
  end
end
