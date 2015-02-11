require 'pp'

module Paasal
  module Adapters
    module V1
      class CloudControlAdapter < Paasal::Adapters::BaseAdapter
        def authenticate(username, password)
          log.debug "Authenticate @ #{@endpoint_url}/token"
          auth_headers = { 'Authorization' => 'Basic ' + ["#{username}:#{password}"].pack('m*').gsub(/\n/, '') }
          response = post('/token', headers: auth_headers)
          # parse date
          expires = Date.parse(response.body[:expires])
          CloudControlToken.new(response.body[:token], expires)
        end

        def applications
          response = get('/app')
          apps = []
          response.body.each do |application|
            apps << to_paasal_app(application, default_deployment(application[:name]))
          end
          apps
        end

        def application(application_id)
          response = get("/app/#{application_id}")
          to_paasal_app(response.body, default_deployment(response.body[:name]))
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

        def to_paasal_app(app, deployment)
          app[:id] = app[:name]
          app[:created_at] = app.delete :date_created
          app[:updated_at] = app.delete :date_modified
          app[:state] = deployment[:state]
          app[:web_url] = deployment[:default_subdomain]
          app[:autoscaled] = false
          app
        end
      end
    end
  end
end