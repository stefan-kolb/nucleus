module Nucleus
  module Adapters
    module V1
      class CloudControl < Stub
        # cloud control, CRUD operations for the application's environment variable object,
        # which is referred to as +config addon+ on the platform.
        module Vars
          # @see Stub#env_vars
          def env_vars(application_id)
            cc_vars = cc_vars(application_id)
            cc_vars.collect do |key, value|
              { id: key, key: key, value: value }
            end
          end

          # @see Stub#env_var
          def env_var(application_id, env_var_key)
            cc_vars = cc_vars(application_id)
            fail Errors::AdapterResourceNotFoundError,
                 "Env. var key '#{env_var_key}' does not exist" unless env_var?(application_id, env_var_key, cc_vars)
            { id: env_var_key, key: env_var_key, value: cc_vars[env_var_key.to_sym] }
          end

          # @see Stub#create_env_var
          def create_env_var(application_id, env_var)
            cc_vars = cc_vars(application_id)
            fail Errors::SemanticAdapterRequestError,
                 "Env. var key '#{env_var[:key]}' already taken" if env_var?(application_id, env_var[:key], cc_vars)
            set_var(application_id, env_var[:key], env_var[:value])
          end

          # @see Stub#update_env_var
          def update_env_var(application_id, env_var_key, env_var)
            cc_vars = cc_vars(application_id)
            fail Errors::AdapterResourceNotFoundError,
                 "Env. var key '#{env_var_key}' does not exist" unless env_var?(application_id, env_var_key, cc_vars)
            set_var(application_id, env_var_key, env_var[:value])
          end

          # @see Stub#delete_env_var
          def delete_env_var(application_id, env_var_key)
            cc_vars = cc_vars(application_id)
            fail Errors::AdapterResourceNotFoundError,
                 "Env. var key '#{env_var_key}' does not exist" unless env_var?(application_id, env_var_key, cc_vars)
            set_var(application_id, env_var_key, nil)
          end

          private

          def cc_vars(application_id)
            cc_vars_response = get("app/#{application_id}/deployment/#{NUCLEUS_DEPLOYMENT}/addon/config.free")
            cc_vars_response.body[:settings][:CONFIG_VARS]
          end

          # Set the variable value (create or update)
          # @param [String] application_id id of the cloud control application
          # @param [Symbol] key variable key name
          # @param [String, Integer, Float, Double] value value to apply to the variable
          # @return [Hash] Nucleus representation of the modified variable
          def set_var(application_id, key, value)
            if value.nil?
              # delete the var, set to 'null'
              settings = "{\"#{key}\":null}"
            else
              settings = "{\"#{key}\":\"#{value}\"}"
            end
            response = put("/app/#{application_id}/deployment/#{NUCLEUS_DEPLOYMENT}/addon/config.free",
                           body: { addon: 'config.free',
                                   settings: settings,
                                   force: true })
            all_vars = response.body[:settings][:CONFIG_VARS]
            { id: key, key: key, value: all_vars[key.to_sym] }
          end

          # Checks if a variable with the env_var_key already exists.
          # @param [String] application_id id of the cloud control application
          # @param [Symbol] env_var_key key name that shall be checked for existence
          # @param [Hash] all_vars collection of currently existing variables for the application
          # @return [Boolean] true if there is a variable with the env_var_key, otherwise false
          def env_var?(application_id, env_var_key, all_vars = nil)
            all_vars = cc_vars(application_id) if all_vars.nil?
            all_vars.key? env_var_key.to_sym
          end
        end
      end
    end
  end
end
