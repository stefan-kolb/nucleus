require 'singleton'

module Nucleus
  module Spec
    module Config
      class AdapterHelper
        include Singleton
        include Nucleus::UrlConverter

        def initialize
          # save them in hash via adapter clazz as key
          @version_based_adapters = {}
          @version_based_endpoints = {}
          Nucleus::VersionDetector.api_versions.each do |api_version|
            adapters = {}
            endpoints = {}
            Nucleus::Adapters.configuration_files.each do |adapter_config|
              vendor = Nucleus::VendorParser.parse(adapter_config)
              adapter_clazz = Nucleus::Adapters.adapter_clazz(adapter_config, api_version)
              vendor.providers.each do |provider|
                provider.endpoints.each do |endpoint|
                  endpoint.url = secure_url(endpoint.url)
                  endpoints[endpoint.id] = endpoint
                  adapters[endpoint.id] = adapter_clazz
                end
              end
            end
            # save adapters for this api_version
            @version_based_adapters[api_version] = adapters
            @version_based_endpoints[api_version] = endpoints
          end
        end

        def load_adapter(endpoint_name, api_version)
          # fail if no such api version actually is available
          raise ArgumentError unless @version_based_adapters.key? api_version
          # fail if no such adapter actually is available
          raise ArgumentError unless @version_based_adapters[api_version].key? endpoint_name
          adapter = @version_based_adapters[api_version][endpoint_name]
          endpoint = @version_based_endpoints[api_version][endpoint_name]
          adapter.new(endpoint.url, endpoint.app_domain, !endpoint.trust)
        end
      end

      # Get the spec adapter configuration
      # @return [Nucleus::Spec::Config::AdapterHelper] Instance of the AdapterHelper
      def self.adapters
        AdapterHelper.instance
      end
    end
  end
end
