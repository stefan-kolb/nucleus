module Paasal
  module Adapters
    module V1
      class Heroku < Stub
        include Paasal::Logging
        include Paasal::Adapters::V1::Heroku::Application
        include Paasal::Adapters::V1::Heroku::AppStates
        include Paasal::Adapters::V1::Heroku::Buildpacks
        include Paasal::Adapters::V1::Heroku::Data
        include Paasal::Adapters::V1::Heroku::Domains
        include Paasal::Adapters::V1::Heroku::Logs
        include Paasal::Adapters::V1::Heroku::Lifecycle
        include Paasal::Adapters::V1::Heroku::Regions
        include Paasal::Adapters::V1::Heroku::Scaler
        include Paasal::Adapters::V1::Heroku::Vars

        def initialize(endpoint_url, endpoint_app_domain = nil, check_certificates = true)
          super(endpoint_url, endpoint_app_domain, check_certificates)
        end

        def authenticate(username, password)
          log.debug "Authenticate @ #{@endpoint_url}"
          response = Excon.new("#{@endpoint_url}/login?username=#{username}&password=#{password}",
                               ssl_verify_peer: @check_certificates).post

          # Heroku returns 404 for invalid credentials
          fail Errors::AuthenticationError, 'Heroku says the credentials are invalid' if response.status == 404

          response_parsed = JSON.parse(response.body)
          api_token = response_parsed['api_key']
          # finally return the header key and value
          { 'Authorization' => "Bearer #{api_token}" }
        end

        def handle_error(error_response)
          if error_response.status == 422
            if error_response.body[:id] == 'invalid_params'
              fail Errors::SemanticAdapterRequestError, error_response.body[:message]
            elsif error_response.body[:id] == 'verification_required'
              fail Errors::PlatformSpecificSemanticError.new(error_response.body[:message],
                                                             API::ErrorMessages::PLATFORM_QUOTA_ERROR)
            end
          elsif error_response.status == 404 && error_response.body[:id] == 'not_found'
            fail Errors::AdapterResourceNotFoundError, error_response.body[:message]
          else
            p error_response
            # TODO: implement me
            log.warn 'Heroku error still unhandled---'
          end
        end

        private

        def install_runtimes(application_id, runtimes)
          runtime_instructions = runtimes.collect { |buildpack_url| { buildpack: buildpack_url } }
          log.debug "Install runtimes: #{runtime_instructions}"
          buildpack_instructions = { updates: runtime_instructions }
          put("/apps/#{application_id}/buildpack-installations", body: buildpack_instructions)
        end

        def runtimes_to_install(application)
          return [] unless application[:runtimes]
          runtimes_to_install = []
          application[:runtimes].each do |runtime_identifier|
            # we do not need to install native buildpacks
            # TODO: 2 options for heroku runtime handling
            # a) skip native, fails when native required and not in list
            # b) (current) use native, fails when others (additional) are in the list
            # next if native_runtime?(runtime_identifier)
            runtime_is_url = runtime_identifier =~ /\A#{URI.regexp}\z/
            runtime_url = find_runtime(runtime_identifier)
            runtime_is_valid = runtime_url || runtime_is_url
            fail Errors::PlatformSpecificSemanticError,
                 "Invalid runtime: #{runtime_identifier} is neither a known runtime, "\
                 'nor a buildpack URL' unless runtime_is_valid
            # if runtime identifier is valid, we need to install the runtime
            runtimes_to_install.push(runtime_is_url ? runtime_identifier : runtime_url)
          end
          # heroku does not know the 'runtimes' property and would crash if present
          application.delete :runtimes
          runtimes_to_install
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

        def installed_buildpacks(application_id)
          buildpacks = get("/apps/#{application_id}/buildpack-installations").body
          return [] if buildpacks.empty?
          buildpacks.collect do |buildpack|
            buildpack[:buildpack][:url]
          end
        end

        def application_instances(application_id)
          formations = get("/apps/#{application_id}/formation").body
          web_formation = formations.find { |formation| formation[:type] == 'web' }
          return web_formation[:quantity] unless web_formation.nil?
          # if no web formation was detected, there is no instance available
          0
        end

        def dynos(application_id)
          get("/apps/#{application_id}/dynos").body
        end

        def web_dynos(application_id, retrieved_dynos = nil)
          all_dynos = retrieved_dynos ? retrieved_dynos : dynos(application_id)
          all_dynos.find_all do |dyno|
            dyno[:type] == 'web'
          end.compact
        end

        def latest_release(application_id, retrieved_dynos = nil)
          dynos = web_dynos(application_id, retrieved_dynos)
          if dynos.nil? || dynos.empty?
            log.debug 'no dynos for build detection, fallback to latest release version'
            # this approach might be wrong if the app is rolled-back to a previous release
            # However, if no dyno is active, this is the only option to identify the current release
            latest_version = 0
            latest_version_id = nil
            get("/apps/#{application_id}/releases").body.each do |release|
              if release[:version] > latest_version
                latest_version = release[:version]
                latest_version_id = release[:id]
              end
            end
            latest_version_id
          else
            latest_version = 0
            latest_version_id = nil
            dynos.each do |dyno|
              if dyno[:release][:version] > latest_version
                latest_version = dyno[:release][:version]
                latest_version_id = dyno[:release][:id]
              end
            end
            latest_version_id
          end
        end

        def to_paasal_app(heroku_application)
          # load dynos only once
          dynos = dynos(heroku_application[:id])
          # add missing fields to the application representation
          heroku_application[:autoscaled] = false
          heroku_application[:state] = application_state(heroku_application, dynos)
          heroku_application[:instances] = application_instances(heroku_application[:id])
          heroku_application[:active_runtime] = heroku_application.delete(:buildpack_provided_description)
          heroku_application[:runtimes] = installed_buildpacks(heroku_application[:id])
          heroku_application[:release_version] = latest_release(heroku_application[:id], dynos)
          heroku_application
        end
      end
    end
  end
end
