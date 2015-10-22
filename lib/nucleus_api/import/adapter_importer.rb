require 'nucleus/core/common/url_converter'

module Nucleus
  module API
    class AdapterImporter
      include Nucleus::Logging
      include Nucleus::UrlConverter

      # Import all API adapters that are described in the adapter configurations.
      #
      # @raise [Nucleus::AmbiguousAdapterError] if more than one adapter was found for an adapter configuration
      def import
        log.debug 'Loading API versions...'
        api_versions = Nucleus::VersionDetector.api_versions

        log.debug 'Loading adapter files...'
        api_versions.each do |api_version|
          log.debug "Loading adapters for API #{api_version}..."
          Nucleus::Adapters.configuration_files.each do |adapter_config|
            import_adapter(adapter_config, api_version)
          end
        end
        log.info 'Adapter import completed'
      end

      private

      def import_adapter(adapter_config, api_version)
        log.debug "... processing #{adapter_config}"
        vendor = Nucleus::VendorParser.parse(adapter_config)
        return if vendor.nil?

        adapter_clazz = Nucleus::Adapters.adapter_clazz(adapter_config, api_version)
        return if adapter_clazz.nil?

        # persist the vendor, but only if a valid adapter was found for this version
        save_vendor(vendor, api_version, adapter_clazz)
      end

      def save_vendor(vendor, api_version, adapter_clazz)
        log.debug "... persisting vendor: #{vendor.name}"
        # instantiate DAOs for this API version
        vendor_dao = Nucleus::API::DB::VendorDao.instance api_version

        save_providers(vendor, api_version, adapter_clazz) unless vendor.providers.nil?
        # finally save the vendor after all nested entities got their IDs if not yet included or shall be overriden
        vendor.providers = vendor.providers.collect(&:id)

        write(vendor_dao, vendor)
      end

      def save_providers(vendor, api_version, adapter_clazz)
        provider_dao = Nucleus::API::DB::ProviderDao.instance api_version

        # finally persist recursively
        vendor.providers.each do |provider|
          log.debug "... persisting provider: #{provider.name}"
          # save the endpoint and assign him an ID
          save_endpoints(provider, api_version, adapter_clazz) unless provider.endpoints.nil?
          # assign the vendor's ID to the provider
          provider.endpoints = provider.endpoints.collect(&:id)
          provider.vendor = vendor.id

          # save the provider after the endpoint if not yet included or shall be overriden
          write(provider_dao, provider)
        end
      end

      def save_endpoints(provider, api_version, adapter_clazz)
        endpoint_dao = Nucleus::API::DB::EndpointDao.instance api_version
        adapter_dao = Nucleus::API::DB::AdapterDao.instance api_version

        provider.endpoints.each do |endpoint|
          log.debug "... persisting endpoint: #{endpoint.name}"
          # assign the provider's ID to the endpoint
          endpoint.provider = provider.id
          # secure the endpoints URL by using only the https scheme
          endpoint.url = secure_url(endpoint.url)
          # save the endpoint if not yet included or shall be overriden
          write(endpoint_dao, endpoint)

          # save in the adapter index entry for fast resolving if not yet included or shall be overriden
          index_entry = AdapterIndexEntry.new('id' => endpoint.id, 'url' => endpoint.url,
                                              'adapter_clazz' => adapter_clazz)
          write(adapter_dao, index_entry)
        end
      end

      def write(dao, object)
        return unless !dao.key?(object.id) || (nucleus_config.db.key?(:override) && nucleus_config.db.override)
        dao.set object
      end
    end
  end
end
