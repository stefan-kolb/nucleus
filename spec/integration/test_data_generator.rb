module Paasal
  module TestDataGenerator
    def self.clean
      paasal_config.api.versions.each do |api_version|
        Paasal::API::DB::AdapterDao.instance(api_version).clear
        Paasal::API::DB::EndpointDao.instance(api_version).clear
        Paasal::API::DB::ProviderDao.instance(api_version).clear
        Paasal::API::DB::VendorDao.instance(api_version).clear
        Paasal::API::DB::CacheDao.instance(api_version).clear
      end
    end
  end

  module DaoResolver
    def self.resolve(entity)
      # TODO: find a solution how to test when multiple API versions are supported
      version = 'v1'
      case entity
      when Paasal::Endpoint
        dao = Paasal::API::DB::EndpointDao.instance(version)
      when Paasal::Provider
        dao = Paasal::API::DB::ProviderDao.instance(version)
      when Paasal::Vendor
        dao = Paasal::API::DB::VendorDao.instance(version)
      when Paasal::AdapterIndexEntry
        dao = Paasal::API::DB::AdapterDao.instance(version)
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
