module Nucleus
  # The {AdapterResolver} can be used within Ruby applications to retrieve a Nucleus adapter.
  # Returned adapters are patched so that each call enforces authentication and retries a call when a token was expired.
  class AdapterResolver
    include Nucleus::UrlConverter

    def initialize(requested_version)
      fail 'No such version supported' unless Nucleus::VersionDetector.api_versions.include?(requested_version)
      @api_version = requested_version
    end

    # Get a list of all adapters that are currently supported.
    # @return [Hash<String, Hash<String, Nucleus::Adapters::BaseAdapter>>] currently supported adapters
    def adapters
      setup
      @adapters
    end

    # Load the adapter to interact with the platform of the vendor that is offered at the endpoint_url.
    # @param [String] vendor The vendor / adapter name that shall be used to communicate with the endpoint.
    #   Must be supported, otherwise a +StandardError+ will be thrown.
    # @param [String] username The username that shall be used for authentication
    # @param [String] password The password that shall be used for authentication
    # @param [Hash<Symbol,?>] options Further options to apply when creating the adapter instance.
    #   If available, the default configuration of the vendor configuration is applied as default.
    # @option options [String] :app_domain The domain where applications of the platform will be made available at.
    #   This option must be set for custom deployments of platforms like Cloud Foundry or Openshift.
    #   For IBM Bluemix this value would be: +eu-gb.mybluemix.net+ or +ng.mybluemix.net+, depending on the endpoint.
    # @option options [String] :check_ssl Set to false if SSL certificates shall not be verified (trust self-signed)
    # @option options [String] :api_url URL of the endpoint's API that shall be used.
    #   Must be specified if there are multiple endpoints available and will be forced to https://
    # @raise [StandardError] if the vendor is unknown / not supported or no unique API endpoint could be identified
    # @return [Nucleus::Adapters::BaseAdapter] loaded adapter implementation
    def load(vendor, username, password, options = {})
      setup
      fail StandardError, "Could not find adapter for vendor '#{vendor}'" unless @adapters.key?(vendor)

      # load the endpoint's HTTPS enabled API URL
      endpoint_url = load_endpoint(vendor, options)

      # load default configuration if available
      if @configurations[vendor].key?(endpoint_url)
        default_configuration = @configurations[vendor][endpoint_url]
        options = default_configuration.merge(options)
      end

      check_ssl = options.key?(:check_ssl) ? options[:check_ssl] : true
      adapter = @adapters[vendor].new(endpoint_url, options[:app_domain], check_ssl)

      fake_env = { 'HTTP_AUTHORIZATION' => 'Basic ' + ["#{username}:#{password}"].pack('m*').gsub(/\n/, '') }
      # patch the adapter so that calls are wrapped and expect valid authentication
      AdapterAuthenticationInductor.patch(adapter, fake_env)

      cache_key = adapter.cache_key(username, password)
      # no auth object available, perform authentication first
      auth_object = adapter.auth_client
      # throws an error if the authentication failed
      auth_object.authenticate(username, password)
      # cache the auth object so it does not have to be retrieved per request
      adapter.cache(cache_key, auth_object)

      # return patched and initially authenticated adapter
      adapter
    end

    private

    def load_endpoint(vendor, options)
      if options.key?(:api_url)
        # use chosen url endpoint
        endpoint_url = options[:api_url]
      elsif @configurations[vendor].length == 1
        # use default endpoint
        endpoint_url = @configurations[vendor].keys.first
      else
        fail StandardError, "Could not identify an API endpoint for the vendor '#{vendor}'. "\
          "Please specify the API URL to use with the ':api_url' option."
      end

      # make sure url uses https
      secure_url(endpoint_url)
    end

    def setup
      # perform the setup only once
      return if @adapters

      # Initialize the application (import adapters, load DAOs, ...)
      require 'paasal/scripts/initialize'
      # load the configuration values
      require 'paasal/scripts/initialize_config_defaults'
      # Once invoked the configuration is locked
      require 'paasal/scripts/finalize'

      @adapters = {}
      @configurations = {}
      Nucleus::Adapters.configuration_files.each do |adapter_config|
        vendor = Nucleus::VendorParser.parse(adapter_config)
        next unless vendor
        adapter_clazz = Nucleus::Adapters.adapter_clazz(adapter_config, @api_version)
        next unless adapter_clazz
        @adapters[vendor.id] = adapter_clazz
        @configurations[vendor.id] = {}

        # now load the default configurations for this vendor
        vendor.providers.each do |provider|
          provider.endpoints.each do |endpoint|
            @configurations[vendor.id][secure_url(endpoint.url)] = { check_ssl: !endpoint.trust,
                                                                     app_domain: endpoint.app_domain }
          end
        end
      end
    end
  end
end
