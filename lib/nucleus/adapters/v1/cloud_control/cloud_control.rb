require 'net/ssh'

module Nucleus
  module Adapters
    module V1
      class CloudControl < Stub
        include Nucleus::Logging
        include Nucleus::Adapters::V1::CloudControl::Authentication
        include Nucleus::Adapters::V1::CloudControl::Application
        include Nucleus::Adapters::V1::CloudControl::Buildpacks
        include Nucleus::Adapters::V1::CloudControl::Domains
        include Nucleus::Adapters::V1::CloudControl::Data
        include Nucleus::Adapters::V1::CloudControl::Lifecycle
        include Nucleus::Adapters::V1::CloudControl::Logs
        include Nucleus::Adapters::V1::CloudControl::Regions
        include Nucleus::Adapters::V1::CloudControl::Scaling
        include Nucleus::Adapters::V1::CloudControl::SemanticErrors
        include Nucleus::Adapters::V1::CloudControl::Services
        include Nucleus::Adapters::V1::CloudControl::Vars

        # The default deployment name of cloud control applications that is used by Nucleus
        NUCLEUS_DEPLOYMENT = 'nucleus'
        # Error messages of semantic errors that are platform specific
        CC_EXCLUSIVE_SEMANTIC_ERROR_MSGS = ['cannot use this name', 'may only contain', 'this field has no more than']
        # Error messages of common semantic errors
        CC_SEMANTIC_ERROR_MSGS = ['must be unique', 'already exists',
                                  'not a valid addon name', 'not a valid addon option']
        CC_CONFLICT_ERROR_MSGS = ['Addon already exists']

        def initialize(endpoint_url, endpoint_app_domain = nil, check_certificates = true)
          super(endpoint_url, endpoint_app_domain, check_certificates)
        end

        def handle_error(error_response)
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

        private

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

        def username
          get('/user').body.first[:username]
        end

        def data_uploaded?(deployment)
          application_id = deployment[:name].split(%r{/})[0]
          repo_host = URI.parse(deployment[:branch]).host
          repo_path = URI.parse(deployment[:branch]).path.gsub(%r{^/}, '').chomp('.git')
          attempts = 0
          with_ssh_key do
            loop do
              begin
                return GitRepoAnalyzer.any_branch?(repo_host, repo_path, application_id)
              rescue Net::SSH::AuthenticationFailed => e
                attempts += 1
                # wait up to 30 seconds
                raise e if attempts >= 15
                log.debug('SSH authentication failed, sleep and repeat')
                # authentication is not yet ready, wait a short time
                sleep(2.0)
              end
            end
          end
        end

        def application_state(deployment)
          # With cloud control not supporting the Nucleus application lifecycle, only 3 actual states remain:<br>
          # * created, when no data deployment (not to confuse with cloud control deployment object) has been made yet
          # * deployed, when only the data has been pushed into the repository (no build)
          # * running, if a data deployment was pushed
          if deployment[:version] == '-1'
            return Enums::ApplicationStates::DEPLOYED if data_uploaded?(deployment)
            return Enums::ApplicationStates::CREATED
          end
          return Enums::ApplicationStates::IDLE if deployment[:state] == 'idle'
          Enums::ApplicationStates::RUNNING
          # return Enums::ApplicationStates::STOPPED

          # arriving here the above states do not catch all states of the cloudControl app, which should not happen ;-)
          # fail Errors::UnknownAdapterCallError, 'Could not determine application state. '\
          #   'Please verify the cloudControl adapter'
        end

        def default_deployment(application_id)
          # get and return nucleus deployment, but catch arising 404 errors
          return get("/app/#{application_id}/deployment/#{NUCLEUS_DEPLOYMENT}").body
        rescue Errors::AdapterResourceNotFoundError
          # if 404, list all deployments
          all_deployments = get("/app/#{application_id}/deployment").body

          # fail 422 (platform specific) if no deployment is available at all
          fail_with(:no_deployment) if all_deployments.length == 0

          # return deployment[0] if collection size is 1
          return all_deployments[0] if all_deployments.length == 1

          # return 'default' if more than 1 deployment and 'default' is included
          def_deployment = all_deployments.find { |d| d[:name].split(%r{/})[1].downcase == 'default' }
          return def_deployment if def_deployment

          # return 'nucleus' if more than 1 deployment, but no 'default' is included
          nucleus_deployment = all_deployments.find { |d| d[:name].split(%r{/})[1].downcase == 'nucleus' }
          return nucleus_deployment if nucleus_deployment

          # fail 422 if no 'default', no 'nucleus', and more than 1 deployment is available (could not identify default)
          fail_with(:ambiguous_deployments)
        end

        def headers
          super.merge('Content-Type' => 'application/json')
        end

        def with_ssh_key
          user = username
          # load ssh key into cloud control
          matches = nucleus_config.ssh.handler.public_key.match(/(.*)\s{1}(.*)\s{1}(.*)/)
          key_id = register_key(user, matches[1], matches[2])
          return yield
        ensure
          # unload ssh key, allow 404 if the key couldn't be registered at first
          delete("/user/#{user}/key/#{key_id}") if key_id
        end
      end
    end
  end
end
