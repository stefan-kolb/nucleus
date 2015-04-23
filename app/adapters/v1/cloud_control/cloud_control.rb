module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        include Paasal::Logging
        include Paasal::Adapters::V1::CloudControl::Application
        include Paasal::Adapters::V1::CloudControl::Buildpacks
        include Paasal::Adapters::V1::CloudControl::Domains
        include Paasal::Adapters::V1::CloudControl::Data
        include Paasal::Adapters::V1::CloudControl::Logs
        include Paasal::Adapters::V1::CloudControl::SemanticErrors
        include Paasal::Adapters::V1::CloudControl::Services
        include Paasal::Adapters::V1::CloudControl::Vars

        # The default deployment name of cloud control applications that is used by PaaSal
        PAASAL_DEPLOYMENT = 'paasal'
        # Error messages of semantic errors that are platform specific
        CC_EXCLUSIVE_SEMANTIC_ERROR_MSGS = ['cannot use this name', 'may only contain', 'this field has no more than']
        # Error messages of common semantic errors
        CC_SEMANTIC_ERROR_MSGS = ['must be unique', 'already exists',
                                  'not a valid addon name', 'not a valid addon option']
        CC_CONFLICT_ERROR_MSGS = ['Addon already exists']

        def initialize(endpoint_url, endpoint_app_domain = nil, check_certificates = true)
          super(endpoint_url, endpoint_app_domain, check_certificates)
        end

        # @see Stub#auth_client
        def auth_client
          Token.new @check_certificates do |_verify_ssl, username, password|
            auth_headers = { 'Authorization' => 'Basic ' + ["#{username}:#{password}"].pack('m*').gsub(/\n/, '') }
            begin
              # ssl verification is implemented by the HttpClient itself
              response = post('/token', headers: auth_headers)
              # parse to retrieve the token and expiration date
              expires = Date.parse(response.body[:expires])
              [response.body[:token], expires]
            rescue Errors::ApiError
              # ignore the error, return nil for failed authentication
              nil
            end
          end
        end

        # @see Stub#regions
        def regions
          [default_region]
        end

        # @see Stub#region
        def region(region_name)
          fail Errors::AdapterResourceNotFoundError,
               "Region '#{region_name}' does not exist at the endpoint" unless region_name.casecmp('default') == 0
          default_region
        end

        def handle_error(error_response)
          # TODO: test if this is valid for all messages
          message = error_response.body.match(/{(.*?)}/)
          message = message[1] if message

          # cloud control responds almost every time with 400...
          if error_response.status == 400
            handle_400(message)
          elsif error_response.status == 409 && CC_CONFLICT_ERROR_MSGS.any? { |msg| message.include? msg }
            fail Errors::SemanticAdapterRequestError, message
          elsif error_response.status == 410
            fail Errors::AdapterResourceNotFoundError, 'Resource not found'
          elsif error_response.status == 503
            fail Errors::PlatformUnavailableError, 'The cloudControl API is currently not available'
          end
          # error still unhandled, will result in a 500, server error
          log.warn "cloudControl error still unhandled: #{error_response}"
        end

        def handle_400(message)
          fail Errors::AdapterResourceNotFoundError, 'Resource not found' if message.nil?

          if message.include?('Billing account required')
            fail_with(:billing_required, [message])
          elsif CC_EXCLUSIVE_SEMANTIC_ERROR_MSGS.any? { |msg| message.include? msg }
            # all these errors are limited to cloud control, e.g. the allowed name characters and max name length
            fail_with(:bad_name, [message])
          elsif CC_SEMANTIC_ERROR_MSGS.any? { |msg| message.include? msg }
            fail Errors::SemanticAdapterRequestError, message
          end
          fail Errors::AdapterRequestError, message
        end

        # @see Stub#scale
        def scale(application_id, instances)
          # update the number of instances on the application's deployment
          scale_response = put("/app/#{application_id}/deployment/#{PAASAL_DEPLOYMENT}",
                               body: { min_boxes: instances }).body
          to_paasal_app(get("/app/#{application_id}").body, scale_response)
        end

        private

        def username
          get('/user').body.first[:username]
        end

        def application_state(deployment)
          # CloudControl does not create a deployment by default.
          # It also does not support start and stop operations.
          # One workaround is to create (start) and delete (stop) all deployments.
          # When stopping, we delete and immediately re-create the deployment.
          # Then its state shall be not deployed, which could be interpreted as equivalent to stopped,
          #  since the deployment code is still in the git repository.
          #
          # With cloud control not supporting the PaaSal application lifecycle, only 2 actual states remain:<br>
          # * created, when no data deployment (not to confuse with cloud control deployment object) has been made yet
          # * running, if a data deployment was pushed
          return API::Models::Application::States::CREATED if deployment[:version] == '-1'
          # return API::Models::Application::States::DEPLOYED
          API::Models::Application::States::RUNNING
          # return API::Models::Application::States::STOPPED
          # return API::Models::Application::States::IDLE

          # arriving here the above states do not catch all states of the cloudControl app, which should not happen ;-)
          # fail Errors::UnknownAdapterCallError, 'Could not determine application state. '\
          #   'Please verify the cloudControl adapter'
        end

        def default_deployment(application_id)
          get("/app/#{application_id}/deployment/#{PAASAL_DEPLOYMENT}").body
        end

        def headers
          super.merge('Content-Type' => 'application/json')
        end

        def default_region
          {
            id: 'default',
            description: 'Default region, cloudControl does not support multi regions yet.',
            created_at: Time.at(0).to_datetime,
            updated_at: Time.at(0).to_datetime
          }
        end
      end
    end
  end
end
