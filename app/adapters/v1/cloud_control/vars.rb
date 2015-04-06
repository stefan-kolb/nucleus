module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        # cloud control, CRUD operations for the application's environment variable object
        module Vars
          # @see Stub#env_vars
          def env_vars(application_id)
            # TODO: implement me
          end

          # @see Stub#env_var
          def env_var(application_id, entity_id)
            # TODO: implement me
          end

          # @see Stub#create_env_var
          def create_env_var(application_id, env_var)
            # TODO: implement me
          end

          # @see Stub#update_env_var
          def update_env_var(application_id, env_var_key, env_var)
            # TODO: implement me
          end

          # @see Stub#delete_env_var
          def delete_env_var(application_id, entity_id)
            # TODO: implement me
          end
        end
      end
    end
  end
end
