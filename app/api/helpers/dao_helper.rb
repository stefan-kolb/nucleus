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

    # Create a DAO for with the given class, but only once per request.
    # Return the existing DAO if it has already been created for the current request
    #
    # @param [class] clazz DAO class for which an instance shall be created
    # @return [Store] concrete DAO store
    def create_dao(clazz)
      if self.respond_to? :version
        begin
          version = self.version
        rescue NoMethodError
        end
      end
      version = self.routes.first.instance_variable_get(:@options)[:version] if version.nil?

      return RequestStore.store[clazz] if RequestStore.exist?(clazz)
      log.debug("Create #{clazz} for API #{version}")
      dao = clazz.new version
      RequestStore.store[clazz] = dao
      dao
    end

  end
end