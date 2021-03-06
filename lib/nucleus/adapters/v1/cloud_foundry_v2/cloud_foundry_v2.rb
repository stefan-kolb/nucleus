module Nucleus
  module Adapters
    module V1
      # The {CloudFoundryV2} adapter is designed to support the Cloud Foundry API and uses only commands
      # of the API version 2.<br>
      # <br>
      # Besides native Cloud Foundry installations, this adapter shall also work with forks, such as Stackato 3.4.2.<br>
      # <br>
      # The Nucleus API is fully supported, there are no known issues.
      # @see http://apidocs.cloudfoundry.org The latest Cloud Foundry API documentation
      class CloudFoundryV2 < Stub
        include Nucleus::Logging
        include Nucleus::Adapters::V1::CloudFoundryV2::Authentication
        include Nucleus::Adapters::V1::CloudFoundryV2::AppStates
        include Nucleus::Adapters::V1::CloudFoundryV2::Buildpacks
        include Nucleus::Adapters::V1::CloudFoundryV2::Application
        include Nucleus::Adapters::V1::CloudFoundryV2::Domains
        include Nucleus::Adapters::V1::CloudFoundryV2::Data
        include Nucleus::Adapters::V1::CloudFoundryV2::Lifecycle
        include Nucleus::Adapters::V1::CloudFoundryV2::Logs
        include Nucleus::Adapters::V1::CloudFoundryV2::Regions
        include Nucleus::Adapters::V1::CloudFoundryV2::Scaling
        include Nucleus::Adapters::V1::CloudFoundryV2::SemanticErrors
        include Nucleus::Adapters::V1::CloudFoundryV2::Services
        include Nucleus::Adapters::V1::CloudFoundryV2::Vars

        def initialize(endpoint_url, endpoint_app_domain = nil, check_certificates = true)
          super(endpoint_url, endpoint_app_domain, check_certificates)
        end

        def handle_error(error)
          cf_error = error.body.is_a?(Hash) ? error.body[:code] : nil
          case error.status
          when 400
            handle_400_error(error, cf_error)
          when 404
            raise Errors::AdapterResourceNotFoundError, error.body[:description] if cf_error > 10_000
          else
            if [1001].include? cf_error
              raise Errors::AdapterRequestError, "#{error.body[:description]} (#{cf_error} - #{error.body[:error_code]})"
            elsif [10_002].include?(cf_error) || error.status == 401
              raise Errors::EndpointAuthenticationError, 'Endpoint authentication failed with OAuth2 token'
            end
          end
          # error still unhandled, will result in a 500, server error
          log.warn "Cloud Foundry error still unhandled: #{error}"
        end

        private

        def handle_400_error(error, cf_error)
          if cf_error == 150_001 || cf_error == 160_001 || cf_error > 100_000 && cf_error < 109_999
            # Indicating semantically invalid parameters
            raise Errors::SemanticAdapterRequestError, error.body[:description]
          elsif cf_error == 170_002
            fail_with(:build_in_progress)
          elsif cf_error == 60_002
            raise Errors::SemanticAdapterRequestError, 'Service is already assigned to the application'
          end
        end

        def guid?(name_or_id)
          Regexp::UUID_PATTERN.match(name_or_id) ? true : false
        end

        def default_organization_guid
          get("/v2/spaces/#{user_space_guid}").body[:entity][:organization_guid]
        end

        def app_guid(app_name_or_id)
          # app name is a UUID and therefore most likely the CF GUID
          return app_name_or_id if guid?(app_name_or_id)
          find_app_guid_by_name(app_name_or_id)
        end

        def find_app_guid_by_name(application_name)
          filtered_list_response = get('/v2/apps', query: { q: "name:#{application_name}" })
          if filtered_list_response.body[:resources].empty?
            raise Errors::AdapterResourceNotFoundError,
                  "Couldn't find app with name '#{application_name}' on the platform"
          end
          # return the found guid
          filtered_list_response.body[:resources][0][:metadata][:guid]
        end

        def find_app_id_by_name(application_name, previous_response)
          filtered_list_response = get('/v2/apps', query: { q: "name:#{application_name}" })
          # fail as expected if the app can also not be found by its name
          if filtered_list_response.body[:resources].empty?
            raise Errors::AdapterResourceNotFoundError,
                  previous_response.body[:description]
          end
          # return the found guid
          filtered_list_response.body[:resources][0][:metadata][:guid]
        end

        def endpoint_info
          get('/v2/info', headers: {}).body
        end

        def user_info
          get("#{endpoint_info[:authorization_endpoint]}/userinfo").body
        end

        def user
          get("/v2/users/#{user_info[:user_id]}").body
        end

        def user_space_guid
          users_spaces = get('/v2/spaces').body[:resources]
          # only once space accessible
          return users_spaces[0][:metadata][:guid] if users_spaces.length == 1
          # use default space (stackato feature)
          default_space = users_spaces.detect { |space_resource| space_resource[:entity][:is_default] == true }
          return default_space[:metadata][:guid] if default_space
          # check the users spaces for default
          user_default_space_guid = user[:entity][:default_space_guid]
          return user_default_space_guid if user_default_space_guid
          # TODO: find a more suitable approach to detect the right space !?
          # multiple spaces and no default space (dammit), choose the first one...
          return users_spaces[0][:metadata][:guid] if users_spaces
          # user has no space assigned, fail since we cant determine a space guid
          fail_with(:no_space_assigned)
        end

        def headers
          super.merge('Basic' => 'Y2Y6', 'Content-Type' => 'application/json')
        end

        def deployed?(application_guid)
          response = head("/v2/apps/#{application_guid}/download", follow_redirects: false, expects: [200, 302, 404])
          return true if response.status == 200 || response.status == 302
          return false if response.status == 404
          # if the response is neither one of the codes, the call fails anyway...
        end

        def app_web_url(app_guid)
          "#{app_guid}.#{@endpoint_app_domain}" if @endpoint_app_domain
        end
      end
    end
  end
end
