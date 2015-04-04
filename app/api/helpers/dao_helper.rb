module Paasal
  module DaoHelper
    extend Grape::API::Helpers
    include Paasal::Logging

    # Get a {Paasal::DB::VendorDao} instance
    # @return [Paasal::DB::VendorDao] DAO instance
    def vendor_dao
      create_dao(Paasal::DB::VendorDao)
    end

    # Get a {Paasal::DB::ProviderDao} instance
    # @return [Paasal::DB::ProviderDao] DAO instance
    def provider_dao
      create_dao(Paasal::DB::ProviderDao)
    end

    # Get a {Paasal::DB::EndpointDao} instance
    # @return [Paasal::DB::EndpointDao] DAO instance
    def endpoint_dao
      create_dao(Paasal::DB::EndpointDao)
    end

    # Get a {Paasal::DB::AdapterDao} instance
    # @return [Paasal::DB::AdapterDao] DAO instance
    def adapter_dao
      create_dao(Paasal::DB::AdapterDao)
    end

    # Get a {Paasal::DB::CacheDao} instance
    # @return [Paasal::DB::CacheDao] DAO instance
    def request_cache
      create_dao(Paasal::DB::CacheDao)
    end

    def load_endpoint(loading_params = params)
      load_entity(endpoint_dao, :endpoint_id, 'endpoint', loading_params)
    end

    def load_provider(loading_params = params)
      load_entity(provider_dao, :provider_id, 'provider', loading_params)
    end

    def load_vendor(loading_params = params)
      load_entity(vendor_dao, :vendor_id, 'vendor', loading_params)
    end

    # Load an entity's instance from the store
    #
    # @param [Paasal::Store] dao the DAO to use for loading
    # @param [Symbol] id symbol where the entities id can be found in the params
    # @param [String] name entities name for error output
    # @param [Hash] params parameters required when called from auth block
    # @return [Paasal::AbstractModel] loaded entity's instance
    def load_entity(dao, id, name, loading_params = params)
      unless dao.key? loading_params[id]
        to_error(Paasal::API::ErrorMessages::NOT_FOUND, "No #{name} found with the ID '#{loading_params[id]}'")
      end
      dao.get loading_params[id]
    end

    # Create a DAO for with the given class, but only once per request.
    # Return the existing DAO if it has already been created for the current request
    #
    # @param [class] clazz DAO class for which an instance shall be created
    # @return [Store] concrete DAO store
    def create_dao(clazz)
      version = version_for_dao
      return RequestStore.store[clazz] if RequestStore.exist?(clazz)
      log.debug("Create #{clazz} for API #{version}")
      dao = clazz.instance version
      RequestStore.store[clazz] = dao
      dao
    end

    def version_for_dao
      routes.first.instance_variable_get(:@options)[:version]
    end
  end
end
