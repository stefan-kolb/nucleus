module Paasal
  module Adapters
    module V1
      class CloudFoundryAdapter < Adapters::BaseAdapter
        include Paasal::Logging

        def initialize(endpoint_url, check_certificates = true)
          super(endpoint_url, check_certificates)
        end

        def authenticate(username, password)
          log.debug "Authenticate @ #{@endpoint_url}/uaa/oauth/token"
          oauth2_client = oauth2("#{@endpoint_url}/uaa/oauth/token")
          # build the client and authenticate for the first time
          oauth2_client.authenticate(username, password)
          oauth2_client
        end

        def applications
          response = get('/v2/apps')
          apps = []
          response.body[:resources].each do |application_resource|
            apps << to_paasal_app(application_resource)
          end
          apps
        end

        def application(application_id)
          response = get("/v2/apps/#{application_id}")
          to_paasal_app(response.body)
        end

        def create_application(application)
          # TODO: implement me
          default_params = { space_guid: default_space_guid }
          application = default_params.merge(application)

          response = post('/v2/apps', body: application)
          to_paasal_app(response.body)
        end

        def update_application(application_id, application_form)
          # TODO: implement me
          # current_application = get("/v2/apps/#{application_id}").body
          # merge existing information with updated values
          # updated_application = current_application.merge application_form
          response = put("/v2/apps/#{application_id}", body: application_form)
          to_paasal_app(response.body)
        end

        def delete_application(application_id)
          delete("/v2/apps/#{application_id}", expects: 204)
        end

        def handle_error(error)
          cf_error = error.body[:code]
          case error.status
          when 400
            if cf_error > 100_000 && cf_error < 109_999
              # Indicating semantically invalid parameters
              fail Errors::SemanticAdapterRequestError, error.body[:description]
            end
          when 404
            if cf_error > 10_000
              fail Errors::AdapterResourceNotFoundError, error.body[:description]
            end
          else
            if [1001].include? cf_error
              fail Errors::AdapterRequestError, "#{error.body[:description]} (#{cf_error} - #{error.body[:error_code]})"
            elsif [10_002].include? cf_error
              fail Errors::OAuth2AuthenticationError, 'Endpoint authentication failed with OAuth2 token'
            end
          end
        end

        def domains(application_id)
          # TODO: implement me
        end

        def domain(application_id, entity_id)
          # TODO: implement me
        end

        def create_domain(application_id, entity_hash)
          # TODO: implement me
        end

        def update_domain(application_id, entity_id, entity_hash)
          # TODO: implement me
        end

        def delete_domain(application_id, entity_id)
          # TODO: implement me
        end

        def env_vars(application_id)
          # TODO: implement me
        end

        def env_var(application_id, entity_id)
          # TODO: implement me
        end

        def create_env_var(application_id, entity_hash)
          # TODO: implement me
        end

        def update_env_var(application_id, entity_id, entity_hash)
          # TODO: implement me
        end

        def delete_env_var(application_id, entity_id)
          # TODO: implement me
        end

        def start(application_id)
          # TODO: implement me
        end

        def stop(application_id)
          # TODO: implement me
        end

        def restart(application_id)
          # TODO: implement me
        end

        private

        def default_space_guid
          default_space = spaces.detect { |space_resource| space_resource[:entity][:is_default] == true }
          default_space[:metadata][:guid]
        end

        def spaces
          response = get('/v2/spaces')
          response.body[:resources]
        end

        def headers
          super.merge(
            'Basic' => 'Y2Y6',
            'Content-Type' => 'application/json'
          )
        end

        def to_paasal_app(app_resource)
          app = app_resource[:entity]
          app[:id] = app.delete :guid
          app[:created_at] = app_resource[:metadata][:created_at]
          app[:updated_at] = app_resource[:metadata][:updated_at] || app_resource[:metadata][:created_at]

          # TODO: Stackato supports autoscaling
          app[:autoscaled] = app.delete(:autoscale_enabled) || false

          # add missing fields to the application representation
          # cf_application[:web_url] = "TO BE DETERMINED"
          # TODO: fetch domains
          # TODO: fetch env vars
          app
        end
      end
    end
  end
end
