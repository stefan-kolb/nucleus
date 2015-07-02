module Paasal
  module API
    # Load and parse the requirement specification for the API version.
    # The requirements must be specified in a 'requirements.yml' file of the API version's directory,
    # e.g. 'app/api/versions/v3/requirements.yml'.
    #
    # @param [String] api_version API version to collect the requirements for
    # @return [Paasal::API::Requirements] requirements of adapters to comply with this API version
    def self.requirements(api_version)
      return @requirements[api_version] unless @requirements.nil? || @requirements[api_version].nil?
      # this is not the schema, but the requirements file (!)
      api_requirements_file = "#{Paasal.src}_api/api/versions/#{api_version}/requirements.yml"
      schema_file = 'schemas/api.requirements.schema.yml'
      schema = Kwalify::Yaml.load_file(schema_file, untabify: true, preceding_alias: true)
      validator = Kwalify::Validator.new(schema)
      parser = Kwalify::Yaml::Parser.new(validator, data_binding: true, preceding_alias: true)
      api_requirements = parser.parse_file(api_requirements_file, untabify: true)
      # requirements are not valid and shall not be returned
      api_requirements = nil if parser.errors && !parser.errors.empty?

      @requirements = {} if @requirements.nil?
      @requirements[api_version] = api_requirements
      api_requirements
    end
  end
end
