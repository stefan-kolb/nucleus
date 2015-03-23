module Paasal
  module API
    module Models
      class EnvironmentVariables < CollectionEntity
        def self.entity_name
          'EnvironmentVariableList'
        end
        item_collection('env_vars', 'environment variables', Models::EnvironmentVariable)
        basic_links('endpoints/%{endpoint_id}/applications/%{application_id}', 'vars')
      end
    end
  end
end
