module Paasal
  module Adapters
    module V1
      # @see https://access.redhat.com/documentation/en-US/OpenShift/2.0/html/REST_API_Guide The Openshift V2
      #   API documentation
      class OpenshiftV2 < Stub
        include Paasal::Logging
        include Paasal::Adapters::V1::OpenshiftV2::Application
        include Paasal::Adapters::V1::OpenshiftV2::AppStates
        include Paasal::Adapters::V1::OpenshiftV2::Data
        include Paasal::Adapters::V1::OpenshiftV2::Domains
        include Paasal::Adapters::V1::OpenshiftV2::SemanticErrors
        include Paasal::Adapters::V1::OpenshiftV2::Lifecycle
        include Paasal::Adapters::V1::OpenshiftV2::Logs
        include Paasal::Adapters::V1::OpenshiftV2::Regions
        include Paasal::Adapters::V1::OpenshiftV2::Vars

        def initialize(endpoint_url, endpoint_app_domain = nil, check_certificates = true)
          super(endpoint_url, endpoint_app_domain, check_certificates)
        end

        # @see Stub#auth_client
        def auth_client
          HttpBasicAuthClient.new @check_certificates do |verify_ssl, headers|
            # auth verification block
            headers['Accept'] = 'application/json; version=1.7'
            result = Excon.new("#{@endpoint_url}/user", ssl_verify_peer: verify_ssl).get(headers: headers)
            # Openshift returns 401 for invalid credentials --> auth failed, return false
            result.status != 401
          end
        end

        def handle_error(error_response)
          errors = error_response.body[:messages].collect { |error| { field: error[:field], text: error[:text] } }
          if error_response.status == 404 && errors.any? { |e| e[:text].include?('not found') }
            fail Errors::AdapterResourceNotFoundError, errors.collect { |e| e[:text] }.join(' ')
          elsif error_response.status == 422
            fail Errors::SemanticAdapterRequestError, errors.collect { |e| e[:text] }.join(' ')
          else
            log.warn "Openshift error still unhandled: #{error_response}"
          end
        end

        # @see Stub#scale
        def scale(application_id, instances)
          id = app_id_by_name(application_id)
          app = get("/application/#{id}").body[:data]
          fail_with(:not_scalable, [application_id]) unless app[:scalable]

          # check if scaling would exceed the available gears
          user = get('/user').body[:data]
          available_gears = user[:max_gears] - user[:consumed_gears]
          requires_additional_gears = instances - app[:gear_count]
          if requires_additional_gears > available_gears
            fail_with(:insufficient_gears, [application_id, instances, requires_additional_gears, available_gears])
          end

          # scale up if we require more gears
          while requires_additional_gears > 0
            send_event(id, 'scale-up')
            requires_additional_gears -= 1
          end

          # scale down if we have too much gears
          while requires_additional_gears < 0
            send_event(id, 'scale-down')
            requires_additional_gears += 1
          end

          # reload the app to see if all operations were taken into account
          application(id)
        end

        private

        def to_paasal_region(region)
          region[:id] = parse_region_name(region.delete(:name))
          # first created zone
          region[:created_at] = region[:zones].min_by { |v| v[:created_at] }
          # last updated zone
          region[:updated_at] = region[:zones].max_by { |v| v[:updated_at] }
          region
        end

        def parse_region_name(region_name)
          # for 'aws-us-east-1'
          parsed_name = /\w+-([a-zA-Z]{2})-\w+-\d/.match(region_name)
          fail Errors::UnknownAdapterCallError, "Invalid region format detected: '#{region_name}'" unless parsed_name
          # we return 'US'
          parsed_name[1].upcase
        end

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
          # TODO: this is actually quite scary, could easily fail with wring timing
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
