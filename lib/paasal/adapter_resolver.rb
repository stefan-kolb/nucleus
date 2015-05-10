module Paasal
  # The {AdapterResolver} can be used within Ruby applications to retrieve a PaaSal adapter.
  # Returned adapters are patched so that each call enforces authentication and retries a call when a token was expired.
  class AdapterResolver
    include Paasal::UrlConverter

    def initialize(api_version)
      fail 'No such API version' unless Paasal::ApiDetector.api_versions.include?(api_version)
      @api_version = api_version
    end

    # Get a list of all adapters that are currently supported.
    # @return [Hash<String, Hash<String, Paasal::Adapters::BaseAdapter>>] currently supported adapters
    def adapters
      setup
      @adapters
    end

    # Load the adapter to interact with the platform of the vendor that is offered at the endpoint_url.
    # @param [String] vendor The vendor / adapter name that shall be used to communicate with the endpoint.
    #   Must be supported, otherwise a +StandardError+ will be thrown.
    # @param [String] endpoint_url The URL endpoint at which the platform is running, which will be forced to https://
    # @param [String] username The username that shall be used for authentication
    # @param [String] password The password that shall be used for authentication
    # @param [Hash<Symbol,?>] options Further options to apply when creating the adapter instance.
    #   If available, the default configuration of the vendor configuration is applied as default.
    # @option options [String] :app_domain The domain where applications of the platform will be made available at.
    #   This option must be set for custom deployments of platforms like Cloud Foundry or Openshift.
    #   For IBM Bluemix this value would be: +eu-gb.mybluemix.net+ or +ng.mybluemix.net+, depending on the endpoint.
    # @option options [String] :check_ssl Set to false if SSL certificates shall not be verified (trust self-signed)
    # @raise [StandardError] if the vendor is unknown / not supported
    def load(vendor, endpoint_url, username, password, options = {})
      setup
      fail StandardError, "Could not find adapter for vendor '#{vendor}'" unless @adapters.key?(vendor)

      # make sure url uses https
      endpoint_url = secure_url(endpoint_url)

      # load default configuration if available
      if @configurations.key?(endpoint_url)
        default_configuration = @configurations[endpoint_url]
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

    def setup
      # Initialize the application (import adapters, load DAOs, ...)
      # Once invoked the configuration is locked
      require 'scripts/initialize'

      # do only once
      return if @adapters
      @adapters = {}
      @configurations = {}
      Paasal::Adapters.configuration_files.each do |adapter_config|
        vendor = Paasal::VendorParser.parse(adapter_config)
        next unless vendor
        adapter_clazz = Paasal::Adapters.adapter_clazz(adapter_config, @api_version)
        next unless adapter_clazz
        @adapters[vendor.id] = adapter_clazz

        # now load the default configurations for this vendor
        vendor.providers.each do |provider|
          provider.endpoints.each do |endpoint|
            @configurations[secure_url(endpoint.url)] = { check_ssl: !endpoint.trust, app_domain: endpoint.app_domain }
          end
        end
      end
    end
  end
end
