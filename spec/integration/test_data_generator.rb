module Nucleus
  module TestDataGenerator
    def self.clean
      nucleus_config.api.versions.each do |api_version|
        Nucleus::API::DB::AdapterDao.instance(api_version).clear
        Nucleus::API::DB::EndpointDao.instance(api_version).clear
        Nucleus::API::DB::ProviderDao.instance(api_version).clear
        Nucleus::API::DB::VendorDao.instance(api_version).clear
        Nucleus::API::DB::CacheDao.instance(api_version).clear
      end
    end
  end

  module DaoResolver
    def self.resolve(entity)
      # TODO: find a solution how to test when multiple API versions are supported
      version = 'v1'
      case entity
      when Nucleus::Endpoint
        dao = Nucleus::API::DB::EndpointDao.instance(version)
      when Nucleus::Provider
        dao = Nucleus::API::DB::ProviderDao.instance(version)
      when Nucleus::Vendor
        dao = Nucleus::API::DB::VendorDao.instance(version)
      when Nucleus::AdapterIndexEntry
        dao = Nucleus::API::DB::AdapterDao.instance(version)
      end
      dao
    end
  end

  class AbstractModel
    def save!
      dao = DaoResolver.resolve self
      dao.set self
    end

    def new_record?
      dao = DaoResolver.resolve self
      dao.key? id
    end
  end

  class AdapterIndexEntry
    def save!
      dao = DaoResolver.resolve self
      dao.set self
    end

    def new_record?
      dao = DaoResolver.resolve self
      dao.key? id
    end
  end
end
