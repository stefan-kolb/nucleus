module Paasal
  module Adapters
    module V1
      class Heroku < Stub
        module Vars
          def env_vars(application_id)
            all_vars = get("/apps/#{application_id}/config-vars").body
            formatted_vars = []
            all_vars.each do |key, value|
              formatted_vars.push(id: key, key: key, value: value)
            end
            formatted_vars
          end

          def env_var(application_id, env_var_key)
            all_vars = get("/apps/#{application_id}/config-vars").body
            fail Errors::AdapterResourceNotFoundError,
                 "Env. var key '#{env_var_key}' does not exist" unless env_var?(application_id, env_var_key, all_vars)

            { id: env_var_key, key: env_var_key, value: all_vars[env_var_key.to_sym] }
          end

          def create_env_var(application_id, env_var)
            fail Errors::SemanticAdapterRequestError,
                 "Env. var key '#{env_var[:key]}' already taken" if env_var?(application_id, env_var[:key])

            request_body = { env_var[:key] => env_var[:value] }
            all_vars = patch("/apps/#{application_id}/config-vars", body: request_body).body
            { id: env_var[:key], key: env_var[:key], value: all_vars[env_var[:key].to_sym] }
          end

          def update_env_var(application_id, env_var_key, env_var)
            fail Errors::AdapterResourceNotFoundError,
                 "Env. var key '#{env_var_key}' does not exist" unless env_var?(application_id, env_var_key)

            request_body = { env_var_key => env_var[:value] }
            updated_vars = patch("/apps/#{application_id}/config-vars", body: request_body).body
            { id: env_var_key, key: env_var_key, value: updated_vars[env_var_key.to_sym] }
          end

          def delete_env_var(application_id, env_var_key)
            fail Errors::AdapterResourceNotFoundError,
                 "Env. var key '#{env_var_key}' does not exist" unless env_var?(application_id, env_var_key)

            # vars can be deleted by setting them to null / nil
            request_body = { env_var_key => nil }
            patch("/apps/#{application_id}/config-vars", body: request_body).body
          end

          private

          def env_var?(application_id, env_var_key, all_vars = nil)
            all_vars = get("/apps/#{application_id}/config-vars").body if all_vars.nil?
            all_vars.key? env_var_key.to_sym
          end
        end
      end
    end
  end
end
