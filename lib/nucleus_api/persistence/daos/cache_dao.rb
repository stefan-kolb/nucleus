module Nucleus
  module API
    module DB
      module CacheDao
        def self.instance(api_version)
          key = "@@__instance__#{api_version}".to_sym
          return class_variable_get(key) if class_variable_defined?(key)
          class_variable_set(key, VersionDependantCacheDao.new(api_version))
        end
      end

      class VersionDependantCacheDao < Nucleus::DB::CacheStore
        include Nucleus::Logging
        include Nucleus::UrlConverter

        def initialize(api_version)
          log.debug "Creating new VersionDependantCacheDao for version #{api_version}"
          super(api_version, 'request_cache')
        end
      end
    end
  end
end
