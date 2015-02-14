require 'singleton'

module Paasal
  module Spec
    module Config
      class AdapterHelper
        include Singleton
        include Paasal::UrlConverter

        def initialize
          # save them in hash via adapter clazz as key
          @version_based_adapters = {}
          @version_based_endpoints = {}
          Paasal::ApiDetector.api_versions.each do |api_version|
            adapters = {}
            endpoints = {}
            Paasal::Adapters.configuration_files.each do |adapter_config|
              vendor = Paasal::VendorParser.parse(adapter_config)
              adapter_clazz = Paasal::Adapters.adapter_clazz(adapter_config, api_version)
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
          fail ArgumentError unless @version_based_adapters.key? api_version
          # fail if no such adapter actually is available
          fail ArgumentError unless @version_based_adapters[api_version].key? endpoint_name
          adapter = @version_based_adapters[api_version][endpoint_name]
          endpoint = @version_based_endpoints[api_version][endpoint_name]
          adapter.new(endpoint.url, !endpoint.trust)
        end
      end

      # Get the spec adapter configuration
      # @return [Paasal::Spec::Config::AdapterHelper] Instance of the AdapterHelper
      def self.adapters
        AdapterHelper.instance
      end
    end
  end
end
