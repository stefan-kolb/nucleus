module Nucleus
  module API
    module DaoHelper
      extend Grape::API::Helpers
      include Nucleus::Logging

      # Get a {Nucleus::API::DB::VendorDao} instance
      # @return [Nucleus::API::DB::VendorDao] DAO instance
      def vendor_dao
        create_dao(Nucleus::API::DB::VendorDao)
      end

      # Get a {Nucleus::API::DB::ProviderDao} instance
      # @return [Nucleus::API::DB::ProviderDao] DAO instance
      def provider_dao
        create_dao(Nucleus::API::DB::ProviderDao)
      end

      # Get a {Nucleus::API::DB::EndpointDao} instance
      # @return [Nucleus::API::DB::EndpointDao] DAO instance
      def endpoint_dao
        create_dao(Nucleus::API::DB::EndpointDao)
      end

      # Get a {Nucleus::API::DB::AdapterDao} instance
      # @return [Nucleus::API::DB::AdapterDao] DAO instance
      def adapter_dao
        create_dao(Nucleus::API::DB::AdapterDao)
      end

      # Get a {Nucleus::API::DB::CacheDao} instance
      # @return [Nucleus::API::DB::CacheDao] DAO instance
      def request_cache
        create_dao(Nucleus::API::DB::CacheDao)
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
      # @param [Nucleus::Store] dao the DAO to use for loading
      # @param [Symbol] id symbol where the entities id can be found in the params
      # @param [String] name entities name for error output
      # @param [Hash] loading_params parameters required when called from auth block
      # @return [Nucleus::AbstractModel] loaded entity's instance
      def load_entity(dao, id, name, loading_params = params)
        to_error(Nucleus::ErrorMessages::NOT_FOUND, "No #{name} found with the ID '#{loading_params[id]}'") unless dao.key? loading_params[id]
        dao.get loading_params[id]
      end

      # Retrieve the DAO for with the given class.
      #
      # @param [class] clazz DAO class for which an instance shall be created
      # @return [Store] concrete DAO store
      def create_dao(clazz)
        version = version_for_dao
        clazz.instance version
      end

      def version_for_dao
        routes.first.instance_variable_get(:@options)[:version]
      end
    end
  end
end
