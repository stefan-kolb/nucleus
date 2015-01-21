module Paasal
  class VendorParser
    include Paasal::Logging

    # Get a parsed vendor instance from the adapter_config file
    #
    # @param [File, String, Path] adapter_config path to the adapter configuration file to be parsed
    # @raise [InvalidAdapterConfigError] if the configuration is invalid
    # @return [Paasal::Vendor] the parsed Vendor instance
    def parse(adapter_config)
      parser = get_parser
      vendor = parser.parse_file(adapter_config)
      errors = parser.errors
      # show errors
      if errors && !errors.empty?
        errors.each do |e|
          log.error "[#{e.path}] #{e.message}"
        end
        raise InvalidAdapterConfigError, 'Invalid adapter configuration. See the logs for detailed information.'
      end
      vendor
    end

    private

    # Create a new (clean) instance of the YML parser
    #
    # @return [Kwalify::Yaml::Parser] new and configured parser instance
    def get_parser
      #schema_file = File.expand_path('../../../../schemas/api.adapter.schema.yml', __FILE__)
      schema_file = 'schemas/api.adapter.schema.yml'
      schema = Kwalify::Yaml.load_file(schema_file, :untabify=>true, :preceding_alias=>true)
      validator = Kwalify::Validator.new(schema)
      Kwalify::Yaml::Parser.new(validator, :data_binding=>true, :preceding_alias=>true)
    end

  end
end
