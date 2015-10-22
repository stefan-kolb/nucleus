module Paasal
  # The API of Nucleus allows to run multiple versions at the same time.
  # Each API version is accessible by using matching accept headers.<br>
  # Nucleus follows the [Semantic Versioning](http://semver.org/) standard.
  # Each not backwards compatible API change must result in a new API version to be released.
  module API
    # The {RootAPI} is the core part of the API, mounting all API versions and including the commonly used features,
    # such as authentication, error rescuing and fallback handling if an route could not be found (404).
    class RootAPI < Grape::API
      # include all shared helpers
      helpers AdapterHelper
      helpers AuthHelper
      helpers DaoHelper
      helpers ErrorHelper
      helpers FormProcessingHelper
      helpers LinkGeneratorHelper
      helpers LogHelper
      helpers SharedParamsHelper

      # we currently use only JSON messages
      content_type :json, 'application/json'
      default_format :json
      default_error_formatter :json
      format :json

      before do
        # env is not injected in every method, we assure to have always access by making it available as instance var
        @env = env
      end

      # rescue ALL errors and comply to the error schema
      rescue_from :all do |e|
        # log the stacktrace only in debug mode
        env['api.endpoint'].log.debug e.to_s
        e.backtrace.each { |line| env['api.endpoint'].log.debug line }

        if e.is_a?(Errors::ApiError) || e.is_a?(Paasal::Errors::AdapterError)
          # willingly sent error, no need for stacktrace
          entity = env['api.endpoint'].build_error_entity(e.ui_error, e.message)
        elsif e.is_a?(Grape::Exceptions::ValidationErrors) || e.is_a?(Grape::Exceptions::InvalidMessageBody)
          entity = env['api.endpoint'].build_error_entity(ErrorMessages::BAD_REQUEST_VALIDATION, e.message)
        elsif e.is_a?(Grape::Exceptions::InvalidAcceptHeader)
          entity = env['api.endpoint'].build_error_entity(ErrorMessages::INVALID_ACCEPT_HEADER, e.message, e.headers)
          env['paasal.invalid.accept.header'] = true
        else
          entity = env['api.endpoint'].build_error_entity(
            ErrorMessages::RESCUED, "Rescued from #{e.class.name}. Could you please report this bug?")
          env['api.endpoint'].log.error("API error via Rack: #{entity[:status]} - #{e.message} (#{e.class}) "\
            "in #{e.backtrace.first}:")
        end

        # send response via Rack, since Grape does not support error! or entities via :with in the rescue block
        ::Rack::Response.new([Models::Error.new(entity).to_json], entity[:status], entity[:headers]).finish
      end

      # ATTENTION (!) BE AWARE THAT THE APIs MUST ALWAYS
      # BE SORTED STARTING WITH THE HIGHEST VERSION

      # include proof-of-concept API, version 2
      # mount Paasal::API::V2::Base

      # include basic API, version 1
      mount Paasal::API::V1::Base

      desc 'Return list of all currently available API versions (root)' do
        success Paasal::API::Models::Api
        failure ErrorResponses.standard_responses
        named 'List API versions'
      end
      get '/' do
        api_versions = []
        # build entity compliant Hash
        nucleus_config.api.versions.each do |api_version|
          api_versions << { name: api_version }
        end

        api = { versions: api_versions }
        present api, with: Paasal::API::Models::Api
      end

      # ATTENTION (!) BE AWARE THAT THIS ROUTE MUST ALWAYS
      # BE PUT AT THE VERY END OF YOUR API

      route :any, '*path' do
        if env['paasal.invalid.accept.header']
          # Internally the error has been cascaded but no route has been found.
          # Now we do want to raise this error instead of a 404, which rack would generate
          to_error(ErrorMessages::INVALID_ACCEPT_HEADER, 'The Accept header does not match to any route. '\
          'Please make sure the vendor is set to \'paasal\' and check the version!')
        else
          # raise 404
          to_error(ErrorMessages::NOT_FOUND, 'Please refer to the API documentation and compare your call '\
          'with the available resources and actions.')
        end
      end
    end
  end
end
