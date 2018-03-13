module Nucleus
  module Adapters
    module V1
      # The {Heroku} adapter is designed to support the Heroku platform API.<br>
      # <br>
      # The Nucleus API is fully supported, there are no known issues.
      # @see https://devcenter.heroku.com/articles/platform-api-reference Heroku Platform API
      class Heroku < Stub
        include Nucleus::Logging
        include Nucleus::Adapters::V1::Heroku::Authentication
        include Nucleus::Adapters::V1::Heroku::Application
        include Nucleus::Adapters::V1::Heroku::AppStates
        include Nucleus::Adapters::V1::Heroku::Buildpacks
        include Nucleus::Adapters::V1::Heroku::Data
        include Nucleus::Adapters::V1::Heroku::Domains
        include Nucleus::Adapters::V1::Heroku::Logs
        include Nucleus::Adapters::V1::Heroku::Lifecycle
        include Nucleus::Adapters::V1::Heroku::Regions
        include Nucleus::Adapters::V1::Heroku::Scaling
        include Nucleus::Adapters::V1::Heroku::Services
        include Nucleus::Adapters::V1::Heroku::SemanticErrors
        include Nucleus::Adapters::V1::Heroku::Vars

        def initialize(endpoint_url, endpoint_app_domain = nil, check_certificates = true)
          super(endpoint_url, endpoint_app_domain, check_certificates)
        end

        def handle_error(error_response)
          handle_422(error_response)
          if error_response.status == 404 && error_response.body[:id] == 'not_found'
            raise Errors::AdapterResourceNotFoundError, error_response.body[:message]
          elsif error_response.status == 503
            raise Errors::PlatformUnavailableError, 'The Heroku API is currently not responding'
          end
          # error still unhandled, will result in a 500, server error
          log.warn "Heroku error still unhandled: #{error_response}"
        end

        def handle_422(error_response)
          return unless error_response.status == 422
          if error_response.body[:id] == 'invalid_params'
            raise Errors::SemanticAdapterRequestError, error_response.body[:message]
          elsif error_response.body[:id] == 'verification_required'
            fail_with(:need_verification, [error_response.body[:message]])
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
            runtime_is_url = runtime_identifier =~ /\A#{URI::DEFAULT_PARSER.make_regexp}\z/
            runtime_url = find_runtime(runtime_identifier)
            runtime_is_valid = runtime_url || runtime_is_url
            fail_with(:invalid_runtime, [runtime_identifier]) unless runtime_is_valid
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
          else
            latest_version = 0
            latest_version_id = nil
            dynos.each do |dyno|
              if dyno[:release][:version] > latest_version
                latest_version = dyno[:release][:version]
                latest_version_id = dyno[:release][:id]
              end
            end
          end

          latest_version_id
        end
      end
    end
  end
end
