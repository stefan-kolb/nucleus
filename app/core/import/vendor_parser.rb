module Paasal
  module VendorParser
    extend Paasal::Logging

    # Get a parsed vendor instance from the adapter_config file
    #
    # @param [File, String, Path] adapter_config path to the adapter configuration file to be parsed
    # @return [Paasal::Vendor] the parsed Vendor instance
    def self.parse(adapter_config)
      schema_file = 'schemas/api.adapter.schema.yml'
      schema = Kwalify::Yaml.load_file(schema_file, untabify: true, preceding_alias: true)
      validator = Kwalify::Validator.new(schema)
      config_parser = Kwalify::Yaml::Parser.new(validator, data_binding: true, preceding_alias: true)

      vendor = config_parser.parse_file(adapter_config)
      errors = config_parser.errors
      # show errors
      if errors && !errors.empty?
        errors.each do |e|
          log.error "[#{e.path}] #{e.message}"
        end
      end
      # vendor is not valid and shall not be returned
      return nil if errors && !errors.empty?
      vendor
    end
  end
end
