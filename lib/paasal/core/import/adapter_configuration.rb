module Paasal
  module Adapters
    extend Paasal::Logging

    # Get all adapter configuration files that are included in the application.
    # The config files must be located at the +config/adapters+ directory.
    #
    # @return [Array<File>] all adapter configuration files
    def self.configuration_files
      return @configuration_files if @configuration_files
      adapter_dir = "#{Paasal.root}/config/adapters"
      files = Dir[File.join(adapter_dir, '*.yml')] | Dir[File.join(adapter_dir, '*.yaml')]
      files = files.flatten.compact
      files.collect! { |file| File.expand_path(file) }
      log.debug "... found #{files.size} adapter config file(s)"
      @configuration_files = files
      @configuration_files
    end

    # Get the clazz to the adapter file that matches the adapter_config and api_version.
    #
    # @param [String] adapter_config adapter configuration that indicates the adapter's name
    # @param [String] api_version API version to load the adapter for
    # @return [String] clazz name of the adapter
    def self.adapter_clazz(adapter_config, api_version)
      adapter_file = adapter_file(adapter_config, api_version)
      return if adapter_file.nil?
      # transform path to clazz and load an instance
      adapter_clazz = "Paasal::Adapters::#{api_version.upcase}::#{File.basename(adapter_file, '.rb').capitalize}"
      adapter_clazz.camelize.split('::').inject(Object) { |a, e| a.const_get e }
    end

    # Get the path to the adapter's class file by translation from the adapter configuration's name.
    # If the adapter configuration is called 'abc-vendor.yml', then the adapter's source file must
    # be found below +app/adapters/#{api_version}/+ with the name +abc-vendor_adapter.rb+.
    #
    # @param [String] adapter_config adapter configuration that indicates the adapter's name
    # @param [String] api_version API version to load the adapter for
    # @raise [Paasal::AmbiguousAdapterError] if more than one adapter was found for an adapter configuration
    # @return [String] path to the adapter's class file
    def self.adapter_file(adapter_config, api_version)
      log.debug "... trying to resolve adapter for config #{adapter_config} and API #{api_version}..."
      adapter_name = File.basename(adapter_config).sub(/.[^.]+\z/, '.rb')
      file_search_path = "#{Paasal.root}/lib/paasal/adapters/#{api_version}/*/#{adapter_name}"
      adapter_file = Dir.glob(file_search_path)
      fail AmbiguousAdapterError, "More than 1 adapter file found for #{adapter_name}" unless adapter_file.size <= 1

      return if adapter_file.empty?
      log.debug "... found '#{adapter_file.first}'"
      adapter_file.first
    end
  end
end
