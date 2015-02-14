require 'heroku-api'

module Paasal
  module Adapters
    module V1
      class HerokuAdapter < Paasal::Adapters::BaseAdapter
        include Paasal::Logging

        def initialize(endpoint_url, check_certificates = true)
          super(endpoint_url, check_certificates)
        end

        def start(application_id)
          log.debug "Start @ #{@endpoint_url}"
          # TODO: implement me
        end

        def stop(application_id)
          log.debug "Stop @ #{@endpoint_url}"
          # TODO: implement me
        end

        def restart(application_id)
          log.debug "Restart @ #{@endpoint_url}"
          # TODO: implement me
        end

        def applications
          # response = Excon.get("#{@endpoint_url}/apps", headers: headers)
          # response_parsed = JSON.parse(response.body, symbolize_names: true)
          # # TODO: convert to compliant Hash
          # response_parsed.each do |application|
          #   to_application application
          # end
          # response_parsed

          response = heroku_api.get_apps
          apps = []
          response.body.each do |application|
            apps << to_paasal_app(application)
          end
          apps
        end

        def application(application_id)
          response = heroku_api.get_app(application_id)
          to_paasal_app response.body
        end

        def delete_application(application_id)
          # returns the application, but we do not want any output
          heroku_api.delete_app(application_id)
        end

        def create_application(application)
          # TODO: implement me
          response = post('/apps', body: application)
          to_paasal_app(response.body)
        end

        def update_application(application_id, application)
          # TODO: implement me
          response = patch("/apps/#{application_id}", body: application)
          to_paasal_app(response.body)
        end

        def authenticate(username, password)
          log.debug "Authenticate @ #{@endpoint_url}"
          # TODO: share the connection
          response = Excon.post("#{@endpoint_url}/login?username=#{username}&password=#{password}")

          # Heroku returns 404 for invalid credentials
          # TODO: customize the error, include proper dev message
          fail Errors::AuthenticationError, 'Heroku says the credentials are invalid' if response.status == 404

          response_parsed = JSON.parse(response.body)
          api_token = response_parsed['api_key']
          # finally return the header key and value
          { 'Authorization' => "Bearer #{api_token}" }
        end

        def handle_error(error_response)
          if error_response.status == 422 && error_response.body[:id] == 'invalid_params'
            fail Errors::AdapterRequestError, error_response.body[:message]
          else
            # TODO: implement me
            log.warn 'Still unhandled---'
          end
          # TODO: handle app not found
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

        private

        def regions
          heroku_api
        end

        def heroku_api
          ::Heroku::API.new(headers: headers)
        end

        def headers
          super.merge(
            'Accept' => 'application/vnd.heroku+json; version=3',
            'Content-Type' => 'application/json'
          )
        end

        def to_paasal_app(heroku_application)
          # add missing fields to the application representation
          heroku_application[:autoscaled] = false
          heroku_application[:state] = 'TO BE DETERMINED'
          heroku_application[:web_url] = 'TO BE DETERMINED'
          # TODO: fetch domains
          # TODO: fetch env vars
          heroku_application
        end
      end
    end
  end
end
