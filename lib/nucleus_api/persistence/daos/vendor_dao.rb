module Nucleus
  module API
    module DB
      module VendorDao
        def self.instance(api_version)
          key = "@@__instance__#{api_version}".to_sym
          return class_variable_get(key) if class_variable_defined?(key)
          class_variable_set(key, VersionDependantVendorDao.new(api_version))
        end
      end

      class VersionDependantVendorDao < Nucleus::DB::Store
        include Nucleus::Logging

        def initialize(api_version)
          log.debug "Creating new VersionDependantVendorDao for version #{api_version}"
          super(api_version, 'vendors')
        end
      end
    end
  end
end
