module Paasal
  module API
    module DB
      module EndpointDao
        def self.instance(api_version)
          key = "@@__instance__#{api_version}".to_sym
          return class_variable_get(key) if class_variable_defined?(key)
          class_variable_set(key, VersionDependantEndpointDao.new(api_version))
        end
      end

      class VersionDependantEndpointDao < Paasal::DB::Store
        include Paasal::Logging

        def initialize(api_version)
          log.debug "Creating new VersionDependantEndpointDao for version #{api_version}"
          super(api_version, 'endpoints')
        end
      end
    end
  end
end
