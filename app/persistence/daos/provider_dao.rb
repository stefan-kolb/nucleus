module Paasal
  module DB
    module ProviderDao
      def self.instance(api_version)
        key = "@@__instance__#{api_version}".to_sym
        return class_variable_get(key) if class_variable_defined?(key)
        class_variable_set(key, VersionDependantProviderDao.new(api_version))
      end
    end

    class VersionDependantProviderDao < Paasal::DB::Store
      include Paasal::Logging

      def initialize(api_version)
        log.debug "Creating new VersionDependantProviderDao for version #{api_version}"
        super(api_version, 'providers')
      end
    end
  end
end
