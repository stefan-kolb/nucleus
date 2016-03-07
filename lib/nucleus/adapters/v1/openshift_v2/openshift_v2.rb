module Nucleus
  module Adapters
    module V1
      # @see https://access.redhat.com/documentation/en-US/OpenShift/2.0/html/REST_API_Guide The Openshift V2
      #   API documentation
      class OpenshiftV2 < Stub
        include Nucleus::Logging
        include Nucleus::Adapters::V1::OpenshiftV2::Authentication
        include Nucleus::Adapters::V1::OpenshiftV2::Application
        include Nucleus::Adapters::V1::OpenshiftV2::AppStates
        include Nucleus::Adapters::V1::OpenshiftV2::Data
        include Nucleus::Adapters::V1::OpenshiftV2::Domains
        include Nucleus::Adapters::V1::OpenshiftV2::Lifecycle
        include Nucleus::Adapters::V1::OpenshiftV2::Logs
        include Nucleus::Adapters::V1::OpenshiftV2::Regions
        include Nucleus::Adapters::V1::OpenshiftV2::Scaling
        include Nucleus::Adapters::V1::OpenshiftV2::SemanticErrors
        include Nucleus::Adapters::V1::OpenshiftV2::Services
        include Nucleus::Adapters::V1::OpenshiftV2::Vars

        def initialize(endpoint_url, endpoint_app_domain = nil, check_certificates = true)
          super(endpoint_url, endpoint_app_domain, check_certificates)
        end

        def handle_error(error_response)
          # some error messages do not have the proper error message format
          errors = openshift_errors(error_response)
          if error_response.status == 404 && errors.any? { |e| e[:text].include?('not found') }
            raise Errors::AdapterResourceNotFoundError, errors.collect { |e| e[:text] }.join(' ')
          elsif error_response.status == 422
            raise Errors::SemanticAdapterRequestError, errors.collect { |e| e[:text] }.join(' ')
          elsif error_response.status == 503
            raise Errors::PlatformUnavailableError, 'The Openshift API is currently not available'
          elsif error_response.status == 504
            raise Errors::PlatformTimeoutError, 'The Openshift API did not receive information from it\'s slaves. '\
              'Most likely the request is still being executed. Please make sure to analyse whether the request '\
              'was successful before invoking further actions.'
          end
          # error still unhandled, will result in a 500, server error
          log.warn "Openshift error still unhandled: #{error_response}"
        end

        def openshift_errors(error_response)
          if error_response.body.is_a?(Hash) && error_response.body.key?(:messages)
            error_response.body[:messages].collect { |error| { field: error[:field], text: error[:text] } }
          else
            []
          end
        end

        private

        def headers
          super.merge('Accept' => 'application/json; version=1.7', 'Content-Type' => 'application/json')
        end

        def app_domain
          # A user always has only 1 domain as described on:
          # https://access.redhat.com/documentation/en-US/OpenShift/2.0/html/REST_API_Guide/chap-API_Guide-Domains.html
          user_domains = get('/domains').body[:data]
          fail_with(:no_user_domain) if user_domains.empty?
          user_domains.first[:name]
        end

        def original_deployment(app, deployments = nil)
          # TODO: this is actually quite scary, could easily fail with wrong timing
          # What are the alternatives?
          # 1) Clone git repo and lookup commits --> insanely slow
          # 2) Identify initial commits by sha1 key --> would require collection of allowed values, which may change!
          deployments = load_deployments(app[:id]) unless deployments
          deployments.find do |deployment|
            diff = (Time.parse(deployment[:created_at]).to_i - Time.parse(app[:creation_time]).to_i).abs
            log.debug "OS deployment time diff: #{diff}"
            diff < 20 && deployment[:force_clean_build] == false &&
              deployment[:hot_deploy] == false && deployment[:ref] == 'master'
          end
        end

        def latest_deployment(application_id, deployments = nil)
          deployments = load_deployments(application_id) unless deployments
          latest = nil
          latest_ts = nil
          deployments.each do |deployment|
            ts = Time.parse(deployment[:created_at]).to_i
            if latest.nil? || ts > latest_ts
              latest = deployment
              latest_ts = ts
            end
          end
          latest
        end

        def active_deployment(app, deployments = nil)
          deployments = load_deployments(app[:id]) unless deployments
          active = nil
          active_ts = nil
          deployments.each do |deployment|
            ts = Time.parse(last_activation(deployment[:activations])).to_i
            if active.nil? || ts > active_ts
              active = deployment
              active_ts = ts
            end
          end
          active
        end

        def last_activation(activations)
          latest = nil
          activations.each do |activation|
            latest = activation if latest.nil? || Time.parse(activation).to_i > Time.parse(latest).to_i
          end
          latest
        end

        def load_deployments(application_id)
          get("/application/#{application_id}/deployments").body[:data]
        end

        def load_gears(application_id)
          get("/application/#{application_id}/gear_groups").body[:data]
        end
      end
    end
  end
end
