module Paasal
  # TODO: document me
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
      stub_class(adapter).instance_methods(false).each do |method_to_wrap|
        # wrap method with authentication repetition call
        patch_method(adapter, method_to_wrap, fake_env)
      end

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

    # Patch the actual method that is defined in an API version stub.
    # The method shall than be able to update the authentication token if the initial authentication expired.<br>
    # Only major authentication issues, e.g. if the credentials are repeatedly rejected,
    # will be thrown to the adapter caller.
    def patch_method(adapter, method_to_wrap, fake_env)
      with_wrapper = :"#{method_to_wrap}_with_before_each_method_call"
      without_wrapper = :"#{method_to_wrap}_without_before_each_method_call"
      @__last_methods_added = [method_to_wrap, with_wrapper, without_wrapper]
      # wrap the method call
      adapter.define_singleton_method with_wrapper do |*args, &block|
        log.debug "Calling adapter method '#{method_to_wrap}' against #{endpoint_url}"
        # use the AuthenticationRetryWrapper to retry calls if tokens expired, ...
        Paasal::Adapters::AuthenticationRetryWrapper.with_authentication(adapter, fake_env) do
          return send without_wrapper, *args, &block
        end
      end
      # now do the actual method re-assignment
      adapter.define_singleton_method without_wrapper, adapter.method(method_to_wrap)
      adapter.define_singleton_method method_to_wrap, adapter.method(with_wrapper)
      @__last_methods_added = nil
    end

    def stub_class(adapter)
      parent = adapter.class
      loop do
        break if parent.superclass == Adapters::BaseAdapter
        parent = parent.superclass
      end
      parent
    end

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
