module Paasal
  module Adapters
    module V1
      class CloudControl < BaseAdapter
        include Paasal::Logging
        include Paasal::Adapters::V1::CloudControl::Application
        include Paasal::Adapters::V1::CloudControl::Buildpacks
        include Paasal::Adapters::V1::CloudControl::Domains
        include Paasal::Adapters::V1::CloudControl::Data
        include Paasal::Adapters::V1::CloudControl::Lifecycle
        include Paasal::Adapters::V1::CloudControl::Logs
        include Paasal::Adapters::V1::CloudControl::Vars
        # all cloud foundry specific semantic errors shall have an error code of 422_6XXX

        def initialize(endpoint_url, endpoint_app_domain = nil, check_certificates = true)
          super(endpoint_url, endpoint_app_domain, check_certificates)
        end

        def authenticate(username, password)
          log.debug "Authenticate @ #{@endpoint_url}/token"
          auth_headers = { 'Authorization' => 'Basic ' + ["#{username}:#{password}"].pack('m*').gsub(/\n/, '') }
          response = post('/token', headers: auth_headers)
          # parse date
          expires = Date.parse(response.body[:expires])
          Token.new(response.body[:token], expires)
        end

        def default_deployment(application_id)
          get("/app/#{application_id}/deployment/paasal").body
        end

        def regions
          [default_region]
        end

        def region(region_name)
          fail Errors::AdapterResourceNotFoundError,
               "Region '#{region_name}' does not exist at the endpoint" unless region_name.casecmp('default') == 0
          default_region
        end

        def handle_error(error_response)
          # TODO: test if this is valid for all messages
          message = error_response.body.match(/{(.*?)}/)
          message = message[1] if message
          if error_response.status == 400
            fail Errors::AdapterResourceNotFoundError, 'Resource not found' if message.nil?

            if message.include?('cannot use this name')
              fail Errors::PlatformSpecificSemanticError, message
            end
            fail Errors::AdapterRequestError, message
          elsif error_response.status == 410
            fail Errors::AdapterResourceNotFoundError, 'Resource not found'
          else
            # TODO: implement me
            log.warn 'Still unhandled---'
          end
        end

        def scale(application_id, instances)
          # update the number of instances on the application's deployment
          scale_response = put("/app/#{application_id}/deployment/paasal", body: { min_boxes: instances }).body
          to_paasal_app(get("/app/#{application_id}").body, scale_response)
        end

        def application_state(application, deployment)
          # TODO: implement me
          # CloudControl does not create a deployment by default.
          # It also does not support start and stop operations.
          # One workaround is to create (start) and delete (stop) all deployments.
          # When stopping, we delete and immediately re-create the deployment.
          # Then its state shall be not deployed, which could be interpreted as equivalent to stopped,
          #  since the deployment code is still in the git repository.
          #
          # State	Object	Native state	Group	Detection order
          # created	git	repository is empty	A	1
          # deployed	git	repository is not empty	A	2
          # deployed	deployments	array length == 0	A	2
          # running	deployments	array length > 0 AND at least one: state == deployed	A	4
          # stopped	deployments	array length > 0 AND for each: state == not deplyoed	A	3
          # suspended	deployments	for each: state == idle	A	4
          #
          # return API::Application::States::CREATED if deployment[:version] == -1
          # return API::Application::States::DEPLOYED
          # return API::Application::States::RUNNING
          # return API::Application::States::STOPPED
          # return API::Application::States::IDLE

          'TO BE DETERMINED'
          # arriving here the above states do not catch all states of the cloudControl app, which should not happen ;-)
          # fail Errors::UnknownAdapterCallError, 'Could not determine application state. '\
          #   'Please verify the cloudControl adapter'
        end

        private

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

        def to_paasal_app(app, deployment)
          app[:id] = app[:name]
          app[:created_at] = app.delete :date_created
          app[:updated_at] = app.delete :date_modified
          app[:state] = application_state(app, deployment)
          app[:web_url] = deployment[:default_subdomain]
          app[:autoscaled] = false
          app[:region] = 'default'
          app[:instances] = deployment[:min_boxes]
          app[:active_runtime] = app[:type][:name] == 'custom' ? app[:buildpack_url] : app[:type][:name]
          app[:runtimes] = [app[:active_runtime]]
          # TODO: verify: version == -1 indicates that there was no deployment
          app[:release_version] = deployment[:version] != -1 ? deployment[:version] : nil
          app
        end
      end
    end
  end
end
