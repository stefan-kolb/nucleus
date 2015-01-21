module Paasal
  class AdapterImporter
    include Paasal::Logging
    include Paasal::UrlConverter

    def initialize
      @adapter_verificator = Paasal::AdapterVerificator.new
      @adapter_resolver = Paasal::AdapterResolver.new
      @vendor_parser = Paasal::VendorParser.new
      @api_detector = Paasal::ApiDetector.new
    end

    # Import all API adapters that are described in the adapter configurations.
    # Before the import, each adapters will be verified if it complies to the API version.
    #
    # @raise [Paasal::InvalidAdapterError] if an adapter is invalid
    # @raise [Paasal::AmbiguousAdapterError] if more than one adapter was found for an adapter configuration
    def import_adapters
      log.debug 'Loading API versions...'
      api_versions = @api_detector.get_api_versions

      log.debug 'Loading adapter files...'
      adapter_config_files = get_adapter_config_files

      api_versions.each do |api_version|
        log.debug "Loading adapters for API #{api_version}..."
        vendor_count = 0
        provider_count = 0
        endpoint_count = 0

        # instantiate DAOs for this API version
        vendor_dao = Paasal::DB::VendorDao.new api_version
        provider_dao = Paasal::DB::ProviderDao.new api_version
        endpoint_dao = Paasal::DB::EndpointDao.new api_version
        adapter_dao = Paasal::DB::AdapterDao.new api_version

        adapter_config_files.each do |adapter_config|
          log.debug "... processing #{adapter_config}"
          vendor = @vendor_parser.parse(adapter_config)
          adapter_file = @adapter_resolver.get_adapter(api_version, adapter_config)

          # persist the vendor, but only if a valid adapter was found for this version
          unless adapter_file.nil?
            adapter_clazz = get_adapter_clazz(adapter_file)
            adapter_instance = adapter_clazz.new('fake url')
            vendor.adapter = adapter_instance

            # verify adapter validity
            @adapter_verificator.verify(adapter_instance, api_version)

            vendor_count += 1
            provider_count += vendor.providers.size unless vendor.providers.nil?

            # finally persist recursively
            vendor.providers.each do |provider|
              # (1), save the provider and assign him an ID
              provider_dao.set provider
              endpoint_count += provider.endpoints.size unless provider.endpoints.nil?
              provider.endpoints.each do |endpoint|
                # (2a), assign the provider's ID to the endpoint
                endpoint.provider = provider.id
                # (2b), secure the endpoints URL by using only the https scheme
                endpoint.url = secure_url(endpoint.url)
                # (3), save the endpoint
                endpoint_dao.set endpoint
                # (4) save in the adapter index entry for fast resolving
                index_entry = AdapterIndexEntry.new({ 'id' => endpoint.id, 'url' => endpoint.url, 'adapter_clazz' => adapter_clazz })
                adapter_dao.set index_entry
              end unless provider.endpoints.nil?
              # (5), assign the vendor's ID to the provider
              provider.endpoints = provider.endpoints.collect { |it| it.id }
              provider.vendor = vendor.id
              # (6), save the provider after the endpoint
              provider_dao.set provider
            end unless vendor.providers.nil?
            # (7), finally save the vendor after all nested entities got their IDs
            vendor.providers = vendor.providers.collect { |it| it.id }
            vendor_dao.set vendor
          end
        end

        log.debug "... loaded #{vendor_count} vendors with #{provider_count} providers and #{endpoint_count} endpoints for API #{api_version}"
      end
    end

    private

    def get_adapter_clazz(adapter_file)
      # transform path to clazz and load an instance
      adapter_class = "Paasal::Adapters::#{File.basename(adapter_file, '.rb').capitalize}".camelize
      adapter_class.split('::').inject(Object) {|o,c| o.const_get c}
    end

    def get_adapter_config_files
      #adapter_dir = File.join(File.dirname(__FILE__), '../../../config/adapters')
      adapter_dir = 'config/adapters'
      files = Dir[File.join(adapter_dir, '*.yml')] | Dir[File.join(adapter_dir, '*.yaml')]
      files = files.flatten.compact
      files.collect! { |file| File.expand_path(file) }
      log.debug "... found #{files.size} adapter config file(s)"
      files
    end

  end
end