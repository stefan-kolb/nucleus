module Nucleus
  module Adapters
    module V1
      class CloudFoundryV2 < Stub
        module Vars
          # @see Stub#env_vars
          def env_vars(application_name_or_id)
            app_guid = app_guid(application_name_or_id)
            app_vars = get("/v2/apps/#{app_guid}/env").body[:environment_json]
            formatted_vars = []
            app_vars.each do |key, value|
              formatted_vars.push(id: key, key: key, value: value)
            end
            formatted_vars
          end

          # @see Stub#env_var
          def env_var(application_name_or_id, env_var_key)
            app_guid = app_guid(application_name_or_id)
            all_vars = get("/v2/apps/#{app_guid}/env").body[:environment_json]
            unless env_var?(app_guid, env_var_key, all_vars)
              raise Errors::AdapterResourceNotFoundError,
                    "Env. var key '#{env_var_key}' does not exist"
            end
            { id: env_var_key, key: env_var_key, value: all_vars[env_var_key.to_sym] }
          end

          # @see Stub#create_env_var
          def create_env_var(application_name_or_id, env_var)
            app_guid = app_guid(application_name_or_id)
            if env_var?(app_guid, env_var[:key])
              raise Errors::SemanticAdapterRequestError,
                    "Env. var key '#{env_var[:key]}' already taken"
            end
            set_var(app_guid, env_var[:key].to_sym, env_var[:value])
          end

          # @see Stub#update_env_var
          def update_env_var(application_name_or_id, env_var_key, env_var)
            app_guid = app_guid(application_name_or_id)
            unless env_var?(app_guid, env_var_key)
              raise Errors::AdapterResourceNotFoundError,
                    "Env. var key '#{env_var_key}' does not exist"
            end
            set_var(app_guid, env_var_key.to_sym, env_var[:value])
          end

          # @see Stub#delete_env_var
          def delete_env_var(application_name_or_id, env_var_key)
            app_guid = app_guid(application_name_or_id)
            unless env_var?(app_guid, env_var_key)
              raise Errors::AdapterResourceNotFoundError,
                    "Env. var key '#{env_var_key}' does not exist"
            end
            request_body = get("/v2/apps/#{app_guid}/env").body[:environment_json]
            request_body.delete(env_var_key.to_sym)
            put("/v2/apps/#{app_guid}", body: { environment_json: request_body }).body[:entity][:environment_json]
          end

          private

          # Set the variable value (create or update) and include all already existing variables
          # to protect them from being deleted.
          # @param [String] app_guid GUID of the CF application
          # @param [Symbol] key variable key name
          # @param [String, Integer, Float, Double] value value to apply to the variable
          # @return [Hash] Nucleus representation of the modified variable
          def set_var(app_guid, key, value)
            request_body = get("/v2/apps/#{app_guid}/env").body[:environment_json]
            request_body[key] = value
            vars = put("/v2/apps/#{app_guid}", body: { environment_json: request_body }).body[:entity]
            { id: key, key: key, value: vars[:environment_json][key] }
          end

          # Checks if a variable with the env_var_key already exists.
          # @param [String] app_guid GUID of the CF application
          # @param [Symbol] env_var_key key name that shall be checked for existence
          # @param [Hash] all_vars collection of currently existing variables for the application
          # @return [Boolean] true if there is a variable with the env_var_key, otherwise false
          def env_var?(app_guid, env_var_key, all_vars = nil)
            all_vars = get("/v2/apps/#{app_guid}/env").body[:environment_json] if all_vars.nil?
            all_vars.key? env_var_key.to_sym
          end
        end
      end
    end
  end
end
