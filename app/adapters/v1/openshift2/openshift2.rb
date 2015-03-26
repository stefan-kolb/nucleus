module Paasal
  module Adapters
    module V1
      class Openshift2 < Stub
        include Paasal::Logging
        include Paasal::Adapters::V1::Openshift2::Application
        include Paasal::Adapters::V1::Openshift2::Data
        include Paasal::Adapters::V1::Openshift2::Domains
        include Paasal::Adapters::V1::Openshift2::Lifecycle
        include Paasal::Adapters::V1::Openshift2::Logs
        include Paasal::Adapters::V1::Openshift2::Vars

        def initialize(endpoint_url, endpoint_app_domain = nil, check_certificates = true)
          super(endpoint_url, endpoint_app_domain, check_certificates)
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

        def regions
          response = get('/regions').body[:data]
          response.each { |region| to_paasal_region(region) }
          # filter all non-available regions
          response.delete_if { |region| region[:allow_selection] == false }
          response
        end

        def region(region_name)
          region = native_region(region_name)
          fail Errors::AdapterResourceNotFoundError,
               "Region '#{region_name}' does not exist at the endpoint" if region.nil?
          region
        end

        def scale(application_id, instances)
          # TODO: implement me
        end

        private

        def native_region(region_name)
          response = get('/regions').body[:data]
          response.delete_if { |region| region[:allow_selection] == false }
          found_region = response.find { |region| parse_region_name(region[:name]).casecmp(region_name) == 0 }
          found_region = to_paasal_region(found_region) unless found_region.nil?
          found_region
        end

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
          app[:region] = parse_region_name(gear_groups[0][:gears][0][:region])
          # TODO: verify
          deployments = get("/application/#{app[:id]}/deployments").body
          app[:release_version] = deployments[0][:sha1]
          app
        end
      end
    end
  end
end
