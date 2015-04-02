module Paasal
  module DB
    module CacheDao
      def self.instance(api_version)
        key = "@@__instance__#{api_version}".to_sym
        return class_variable_get(key) if class_variable_defined?(key)
        class_variable_set(key, VersionDependantCacheDao.new(api_version))
      end
    end

    class VersionDependantCacheDao < Paasal::DB::CacheStore
      include Paasal::Logging
      include Paasal::UrlConverter

      def initialize(api_version)
        log.debug "Creating new VersionDependantCacheDao for version #{api_version}"
        super(api_version, 'request_cache')
      end
    end
  end
end
