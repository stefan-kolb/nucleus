module Paasal
  module Adapters
    module V1
      class CloudFoundryAdapter < Adapters::BaseAdapter
        include Paasal::Logging
        include Paasal::Adapters::V1::CloudFoundryBuildpacks
        include Paasal::Adapters::V1::CloudFoundryAdapterApplication
        include Paasal::Adapters::V1::CloudFoundryAdapterData
        include Paasal::Adapters::V1::CloudFoundryAdapterDomains
        include Paasal::Adapters::V1::CloudFoundryAdapterLifecycle
        include Paasal::Adapters::V1::CloudFoundryAdapterVars
        # all cloud foundry specific semantic errors shall have an error code of 422_5XXX

        def initialize(endpoint_url, endpoint_app_domain = nil, check_certificates = true)
          super(endpoint_url, endpoint_app_domain, check_certificates)
        end

        def authenticate(username, password)
          auth_endpoint = endpoint_info[:authorization_endpoint]
          log.debug "Authenticate @ #{auth_endpoint}/oauth/token"
          oauth2_client = oauth2("#{auth_endpoint}/oauth/token")
          # build the client and authenticate for the first time
          oauth2_client.authenticate(username, password)
          oauth2_client
        end

        def handle_error(error)
          cf_error = error.body[:code]
          case error.status
          when 400
            handle_400_error(error, cf_error)
          when 404
            fail Errors::AdapterResourceNotFoundError, error.body[:description] if cf_error > 10_000
          else
            if [1001].include? cf_error
              fail Errors::AdapterRequestError, "#{error.body[:description]} (#{cf_error} - #{error.body[:error_code]})"
            elsif [10_002].include? cf_error
              fail Errors::OAuth2AuthenticationError, 'Endpoint authentication failed with OAuth2 token'
            end
          end
          log.debug 'Unhandled CF error'
          log.debug error
        end

        def handle_400_error(error, cf_error)
          if cf_error == 150_001 || cf_error == 160_001 || cf_error > 100_000 && cf_error < 109_999
            # Indicating semantically invalid parameters
            fail Errors::SemanticAdapterRequestError, error.body[:description]
          elsif cf_error == 170_002
            fail Errors::PlatformSpecificSemanticError, 'Application is still building'
          end
        end

        def scale(application_name_or_id, instances)
          # update the number of instances on the application
          update_application(application_name_or_id, instances: instances)
        end

        def regions
          [default_region]
        end

        def region(region_name)
          fail Errors::AdapterResourceNotFoundError,
               "Region '#{region_name}' does not exist at the endpoint" unless region_name.casecmp('default') == 0
          default_region
        end

        private

        def default_organization_guid
          get("/v2/spaces/#{user_space_guid}").body[:entity][:organization_guid]
        end

        def app_guid(app_name_or_id)
          if /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.match(app_name_or_id)
            # app name is a UUID and therefore most likely the CF GUID
            return app_name_or_id
          end
          find_app_guid_by_name(app_name_or_id)
        end

        def find_app_guid_by_name(application_name)
          filtered_list_response = get('/v2/apps', query: { q: "name:#{application_name}" })
          if filtered_list_response.body[:resources].length == 0
            fail Errors::AdapterResourceNotFoundError,
                 "Couldn't find app with name '#{application_name}' on the platform"
          end
          # return the found guid
          filtered_list_response.body[:resources][0][:metadata][:guid]
        end

        def find_app_id_by_name(application_name, previous_response)
          filtered_list_response = get('/v2/apps', query: { q: "name:#{application_name}" })
          # fail as expected if the app can also not be found by its name
          fail Errors::AdapterResourceNotFoundError,
               previous_response.body[:description] if filtered_list_response.body[:resources].length == 0
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

        def default_region
          {
            id: 'default',
            description: 'Default region, Cloud Foundry does not support multi regions yet.',
            created_at: Time.at(0).to_datetime,
            updated_at: Time.at(0).to_datetime
          }
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
          fail Errors::SemanticAdapterRequestError.new('User is not assigned to any space', '422_5002')
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

        def application_state(app_resource)
          if app_resource[:entity][:state] == 'STARTED'
            # 1: crashed
            return API::Application::States::CRASHED if app_resource[:entity][:package_state] == 'FAILED'
            # 1: started
            return API::Application::States::RUNNING if app_resource[:entity][:package_state] == 'STAGED'
          end

          # 4: stopped if there is a detected buildpack
          return API::Application::States::STOPPED unless app_resource[:entity][:staging_task_id].nil?
          # 3: deployed if stopped but no data can be downloaded
          return API::Application::States::DEPLOYED if deployed?(app_resource[:metadata][:guid])
          # 2: created if stopped and no buildpack detected
          API::Application::States::CREATED
        end

        # TODO: handle duplicate name
        # TODO: handle CF-AppMemoryQuotaExceeded --> QuotaError as custom 422

        def app_web_url(app_guid)
          "#{app_guid}.#{@endpoint_app_domain}" if @endpoint_app_domain
        end

        def to_paasal_app(app_resource)
          metadata = app_resource[:metadata]
          app = app_resource[:entity]

          app[:id] = metadata[:guid]
          app[:created_at] = metadata[:created_at]
          app[:updated_at] = metadata[:updated_at] || metadata[:created_at]
          app[:state] = application_state(app_resource)
          app[:web_url] = "http://#{app_web_url(metadata[:guid])}"
          # route could have been deleted by the user
          app[:web_url] = nil unless domain?(metadata[:guid], app[:web_url])
          # Stackato does support autoscaling
          app[:autoscaled] = app.delete(:autoscale_enabled) || false
          app[:region] = 'default'
          app[:active_runtime] = app[:detected_buildpack]
          app[:runtimes] = app[:buildpack] ? [app[:buildpack]] : []
          app[:release_version] = app.delete(:version)
          app
        end
      end
    end
  end
end
