module Paasal
  module Adapters
    module V1
      class Openshift2Adapter < Paasal::Adapters::BaseAdapter
        include Paasal::Logging

        def initialize(endpoint_url, check_certificates = true)
          super(endpoint_url, check_certificates)
        end

        def authenticate(username, password)
          # access the user information to prove authentication is granted
          response = Excon.get("#{@endpoint_url}/user",
                               headers: { 'Accept' => 'application/json; version=1.7',
                                          'Authorization' => 'Basic ' +
                                              ["#{username}:#{password}"].pack('m*').gsub(/\n/, '') })

          # Openshift returns 401 for invalid credentials
          fail Errors::AuthenticationError, 'Openshift says the credentials are invalid' if response.status == 401

          # once authenticated, return the header
          { 'Authorization' => 'Basic ' + ["#{username}:#{password}"].pack('m*').gsub(/\n/, '') }
        end

        def applications
          response = get('/applications')
          apps = []
          response.body[:data].each do |application|
            apps << application(application[:id])
          end
          apps
        end

        def application(application_id)
          app_response = get("/application/#{application_id}")
          app_gear_groups = get("/application/#{application_id}/gear_groups")
          to_paasal_app app_response.body[:data], app_gear_groups.body[:data]
        end

        def default_deployment(application_id)
          get("/app/#{application_id}/deployment/default")
        end

        def create_application(entity_hash)
          # TODO: implement me
        end

        def update_application(entity_id, entity_hash)
          # TODO: implement me
        end

        def delete_application(entity_id)
          # TODO: implement me
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

        def headers
          super.merge('Accept' => 'application/json; version=1.7')
        end

        def to_paasal_app(app, gear_groups)
          # app[:id] = app[:name]
          app[:created_at] = app.delete :creation_time
          app[:updated_at] = nil
          # TODO: handle mixed gear states and convert
          app[:state] = gear_groups[0][:gears][0][:state]
          app[:web_url] = app.delete :app_url
          app[:autoscaled] = app.delete :scalable
          app
        end
      end
    end
  end
end
