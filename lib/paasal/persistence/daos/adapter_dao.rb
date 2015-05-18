module Paasal
  module DB
    module AdapterDao
      def self.instance(api_version)
        key = "@@__instance__#{api_version}".to_sym
        return class_variable_get(key) if class_variable_defined?(key)
        class_variable_set(key, VersionDependantAdapterDao.new(api_version))
      end
    end

    class VersionDependantAdapterDao < Paasal::DB::Store
      include Paasal::Logging
      include Paasal::UrlConverter

      def initialize(api_version)
        log.debug "Creating new VersionDependantAdapterDao for version #{api_version}"
        super(api_version, 'adapter_index')
      end

      def set(entity)
        # secure the URL, always convert to https (!)
        entity.url = secure_url(entity.url)
        super(entity)
      end
    end
  end
end
