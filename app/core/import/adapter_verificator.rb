module Paasal
  class AdapterVerificator
    include Paasal::Logging

    # Assert that an Adapter implements all required API methods and
    # return those methods that are not implemented.
    #
    # @param [Paasal::Adapters::BaseAdapter] adapter The adapter that shall be verified
    # @param [String] api_version The version of the API that the adapter shall comply to
    # @raise [Paasal::InvalidAdapterError] if at least one required method has not been implemented in the Adapter
    # @return [void]
    def verify(adapter, api_version)
      api_requirements = get_api_requirements(api_version)
      # check that all required methods are implemented
      missing_methods = []
      invalid_arguments = []
      api_requirements.methods.each do |required_method|
        if !adapter.respond_to? required_method.name
          missing_methods << required_method.name
          log.fatal "Invalid Adapter '#{adapter.class.name.underscore}', does not implement the method for "\
            "API #{api_version}: #{required_method.name}"
        elsif adapter.method(required_method.name).arity != required_method.arguments
          invalid_arguments << required_method.name
          log.fatal "Invalid Adapter '#{adapter.class.name.underscore}', wrong number of method arguments "\
             "for API #{api_version}: #{required_method.name}, expected #{required_method.arguments} but "\
             "found #{adapter.method(required_method.name).arity}"
        end
      end
      unless missing_methods.empty? && invalid_arguments.empty?
        raise Paasal::InvalidAdapterError, "Adapter '#{adapter}' has invalid methods that are required by API #{api_version}"
      end
      return nil
    end

    private

    # Load and parse the requirement specification for the API version.
    # The requirements must be specified in a 'requirements.yml' file of the API version's directory,
    # e.g. 'app/api/versions/v3/requirements.yml'.
    #
    # @param [String] api_version API version to collect the requirements for
    def get_api_requirements(api_version)
      # this is not the schema, but the requirements file (!)
      #api_requirements_file = File.expand_path("../../../api/versions/#{api_version}/requirements.yml", __FILE__)
      api_requirements_file = "app/api/versions/#{api_version}/requirements.yml"
      #schema_file = File.expand_path('../../../../schemas/api.requirements.schema.yml', __FILE__)
      schema_file = 'schemas/api.requirements.schema.yml'
      schema = Kwalify::Yaml.load_file(schema_file, :untabify=>true, :preceding_alias=>true)
      validator = Kwalify::Validator.new(schema)
      parser = Kwalify::Yaml::Parser.new(validator, :data_binding=>true, :preceding_alias=>true)
      api_requirements = parser.parse_file(api_requirements_file, :untabify=>true)
      api_requirements
    end

  end
end