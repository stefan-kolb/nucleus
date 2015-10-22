module Nucleus
  module Adapters
    module V1
      class OpenshiftV2 < Stub
        module Vars
          # @see Stub#env_vars
          def env_vars(application_id)
            all_vars = get("/application/#{app_id_by_name(application_id)}/environment-variables").body[:data]
            all_vars.collect { |var| to_nucleus_var(var) }
          end

          # @see Stub#env_var
          def env_var(application_id, env_var_key)
            response = get("/application/#{app_id_by_name(application_id)}/environment-variable/#{env_var_key}")
            to_nucleus_var(response.body[:data])
          end

          # @see Stub#create_env_var
          def create_env_var(application_id, env_var)
            to_nucleus_var(post("/application/#{app_id_by_name(application_id)}/environment-variables",
                               body: { name: env_var[:key], value: env_var[:value] }).body[:data])
          end

          # @see Stub#update_env_var
          def update_env_var(application_id, env_var_key, env_var)
            to_nucleus_var(put("/application/#{app_id_by_name(application_id)}/environment-variable/#{env_var_key}",
                              body: { value: env_var[:value] }).body[:data])
          end

          # @see Stub#delete_env_var
          def delete_env_var(application_id, env_var_key)
            id = app_id_by_name(application_id)
            # Openshift returns 204 even if the key did not exist
            if get("/application/#{id}/environment-variable/#{env_var_key}", expects: [200, 404]).status == 404
              fail Errors::AdapterResourceNotFoundError, "Env. var key '#{env_var_key}' does not exist"
            end
            delete("/application/#{id}/environment-variable/#{env_var_key}")
          end

          private

          def to_nucleus_var(var)
            { id: var[:name], key: var[:name], value: var[:value] }
          end
        end
      end
    end
  end
end
