module Paasal
  module API
    module V1
      class ApplicationEnvVars < Grape::API
        helpers SharedParamsHelper

        params do
          use :application_context
        end
        resource 'endpoints/:endpoint_id/applications/:application_id/vars',
                 desc: 'Application environment variable operations',
                 swagger: { nested: false, name: 'application-vars' } do
          desc 'List of the application\'s environment variables' do
            success Models::EnvironmentVariables
            failure [[200, 'Environment variables retrieved',
                      Models::EnvironmentVariables]].concat ErrorResponses.standard_responses
          end
          get '/' do
            vars = with_authentication { adapter.env_vars(params[:application_id]) }
            present vars, with: Models::EnvironmentVariables
          end

          desc 'Create an environment variable' do
            success Models::EnvironmentVariable
            failure [[201, 'Environment variable set',
                      Models::EnvironmentVariable]].concat ErrorResponses.standard_responses
          end
          params do
            requires :variable, type: Hash do
              # we only need the key and the value
              requires :all, using: Paasal::API::Models::EnvironmentVariable.documentation.slice(:key, :value)
            end
          end
          post '/' do
            var_params = declared(params, include_missing: false)[:variable]
            var = with_authentication { adapter.create_env_var(params[:application_id], var_params) }
            present var, with: Models::EnvironmentVariable
          end

          params do
            use :env_var_id
          end
          resource '/:env_var_id' do
            desc 'Show an environment variable' do
              success Models::EnvironmentVariable
              failure [[200, 'Environment variable retrieved',
                        Models::EnvironmentVariable]].concat ErrorResponses.standard_responses
            end
            get '/' do
              var = with_authentication { adapter.env_var(params[:application_id], params[:env_var_id]) }
              present var, with: Models::EnvironmentVariable
            end

            desc 'Update an environment variable\'s value' do
              success Models::EnvironmentVariable
              failure [[200, 'Environment variable updated',
                        Models::EnvironmentVariable]].concat ErrorResponses.standard_responses
            end
            params do
              requires :variable, type: Hash do
                # we only need the updated value
                requires :all, using: Paasal::API::Models::EnvironmentVariable.documentation.slice(:value)
              end
            end
            patch '/' do
              var_params = declared(params, include_missing: false)[:variable]
              var = with_authentication do
                adapter.update_env_var(params[:application_id], params[:env_var_id], var_params)
              end
              present var, with: Models::EnvironmentVariable
            end

            desc 'Delete an environment variable' do
              failure [[204, 'Environment variable deleted']].concat ErrorResponses.standard_responses
            end
            delete '/' do
              with_authentication { adapter.delete_env_var(params[:application_id], params[:env_var_id]) }
              # respond with 204 when entity is deleted (see rfc7231)
              status 204
            end
          end
        end # end of resource
      end
    end
  end
end
