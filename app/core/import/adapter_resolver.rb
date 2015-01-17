module Paasal
  class AdapterResolver
    include Paasal::Logging

    # Get the path to the adapter's class file by translation from the adapter configuration's name.
    # If the adapter configuration is called 'abc-vendor.yml', then the adapter's source file must
    # be found below 'app/adapters/#{api_version}/' with the name 'abc-vendor_adapter.rb'.
    #
    # @param [String] api_version API version to load the adapter for
    # @param [String] adapter_config adapter configuration that indicates the adapter's name
    # @raise [Paasal::AmbiguousAdapterError] if more than one adapter was found for an adapter configuration
    # @return [String] path to the adapter's class file
    def get_adapter(api_version, adapter_config)
      log.debug "... trying to resolve adapter for config #{adapter_config} and API #{api_version}..."
      adapter_name = File.basename(adapter_config).sub(/.[^.]+\z/, '_adapter.rb')
      #file_search_path = File.expand_path("../../../adapters/#{api_version}/*/#{adapter_name}", __FILE__)
      file_search_path = "app/adapters/#{api_version}/*/#{adapter_name}"
      adapter_file = Dir.glob(file_search_path)
      raise AmbiguousAdapterError, "More than 1 adapter file found for #{adapter_name}" unless adapter_file.size <= 1

      return if adapter_file.empty?
      log.debug "... found '#{adapter_file.first}'"
      return adapter_file.first
    end

  end
end