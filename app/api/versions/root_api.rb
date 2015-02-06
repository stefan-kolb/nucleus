module Paasal
  module API
    class RootAPI < Grape::API
      # include all shared helpers
      helpers Paasal::AdapterHelper
      helpers Paasal::DaoHelper
      helpers Paasal::ErrorHelper
      helpers Paasal::FormProcessingHelper
      helpers Paasal::LinkGeneratorHelper
      helpers Paasal::LogHelper
      helpers Paasal::ResponseHelper
      helpers Paasal::SharedParamsHelper

      # TODO: mayby we need those for request parameters?
      # content_type :xml, 'application/xml'
      content_type :json, 'application/json'
      # content_type :binary, 'application/octet-stream'
      # content_type :txt, 'text/plain'
      default_format :json
      default_error_formatter :json
      format :json

      # rescue ALL errors and comply to the error schema
      rescue_from :all do |e|
        if e.is_a? Errors::ApiError
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
          # log the stacktrace only in debug mode
          e.backtrace.each { |line| env['api.endpoint'].log.debug line }
        end

        # send response via Rack, since Grape does not support error! or entities via :with in the rescue block
        rack_response API::Models::Error.new(entity).to_json, entity[:status], entity[:headers]
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
        configatron.api.versions.each do |api_version|
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
