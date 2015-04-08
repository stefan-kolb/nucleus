module Paasal
  class AdapterImporter
    include Paasal::Logging
    include Paasal::UrlConverter

    # Import all API adapters that are described in the adapter configurations.
    #
    # @raise [Paasal::AmbiguousAdapterError] if more than one adapter was found for an adapter configuration
    def import
      log.debug 'Loading API versions...'
      api_versions = Paasal::ApiDetector.api_versions

      log.debug 'Loading adapter files...'
      api_versions.each do |api_version|
        log.debug "Loading adapters for API #{api_version}..."
        Paasal::Adapters.configuration_files.each do |adapter_config|
          import_adapter(adapter_config, api_version)
        end
      end
      log.info 'Adapter import completed'
    end

    private

    def import_adapter(adapter_config, api_version)
      log.debug "... processing #{adapter_config}"
      vendor = Paasal::VendorParser.parse(adapter_config)
      return if vendor.nil?

      adapter_clazz = Paasal::Adapters.adapter_clazz(adapter_config, api_version)
      return if adapter_clazz.nil?

      # persist the vendor, but only if a valid adapter was found for this version
      save_vendor(vendor, api_version, adapter_clazz)
    end

    def save_vendor(vendor, api_version, adapter_clazz)
      log.debug "... persisting vendor: #{vendor.name}"
      # instantiate DAOs for this API version
      vendor_dao = Paasal::DB::VendorDao.instance api_version

      save_providers(vendor, api_version, adapter_clazz) unless vendor.providers.nil?
      # (7), finally save the vendor after all nested entities got their IDs if not yet included or shall be overriden
      vendor.providers = vendor.providers.collect(&:id)

      return unless !vendor_dao.key?(vendor.id) || configatron.db.key?(:override) && configatron.db.override
      vendor_dao.set vendor
    end

    def save_providers(vendor, api_version, adapter_clazz)
      provider_dao = Paasal::DB::ProviderDao.instance api_version

      # finally persist recursively
      vendor.providers.each do |provider|
        log.debug "... persisting provider: #{provider.name}"
        # (1), save the provider and assign him an ID
        provider_dao.set provider
        save_endpoints(provider, api_version, adapter_clazz) unless provider.endpoints.nil?
        # (5), assign the vendor's ID to the provider
        provider.endpoints = provider.endpoints.collect(&:id)
        provider.vendor = vendor.id

        # (6), save the provider after the endpoint if not yet included or shall be overriden
        return unless !provider_dao.key?(provider.id) || configatron.db.key?(:override) && configatron.db.override
        provider_dao.set provider
      end
    end

    def save_endpoints(provider, api_version, adapter_clazz)
      endpoint_dao = Paasal::DB::EndpointDao.instance api_version
      adapter_dao = Paasal::DB::AdapterDao.instance api_version

      provider.endpoints.each do |endpoint|
        log.debug "... persisting endpoint: #{endpoint.name}"
        # (2a), assign the provider's ID to the endpoint
        endpoint.provider = provider.id
        # (2b), secure the endpoints URL by using only the https scheme
        endpoint.url = secure_url(endpoint.url)
        # (3), save the endpoint if not yet included or shall be overriden
        if !endpoint_dao.key?(endpoint.id) || configatron.db.key?(:override) && configatron.db.override
          endpoint_dao.set endpoint
        end

        # (4) save in the adapter index entry for fast resolving if not yet included or shall be overriden
        index_entry = AdapterIndexEntry.new('id' => endpoint.id, 'url' => endpoint.url,
                                            'adapter_clazz' => adapter_clazz)
        return unless !adapter_dao.key?(index_entry.id) || configatron.db.key?(:override) && configatron.db.override
        adapter_dao.set index_entry
      end
    end
  end
end
