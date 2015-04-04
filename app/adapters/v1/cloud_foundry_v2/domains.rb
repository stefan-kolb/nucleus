module Paasal
  module Adapters
    module V1
      class CloudFoundryV2 < Stub
        # Application domain / route functionality to support the Cloud Foundry API.<br>
        module Domains
          def domains(domain_id)
            app_guid = app_guid(domain_id)
            assigned_routes = get("/v2/apps/#{app_guid}/routes").body
            domains = []
            assigned_routes[:resources].each do |assigned_route|
              paasal_domain = route_to_paasal_domain(assigned_route)
              domains.push(paasal_domain) unless paasal_domain[:name] == app_web_url(app_guid)
            end
            domains
          end

          def domain(application_name_or_id, domain_id)
            app_guid = app_guid(application_name_or_id)
            assigned_routes = get("/v2/apps/#{app_guid}/routes").body
            assigned_routes[:resources].each do |assigned_route|
              return route_to_paasal_domain(assigned_route) if assigned_route[:metadata][:guid] == domain_id
            end
          end

          def create_domain(application_name_or_id, domain)
            domains(application_name_or_id).each do |existing_domain|
              if existing_domain[:name] == domain[:name]
                fail Errors::SemanticAdapterRequestError,
                     "Domain '#{domain[:name]}' is already assigned to the application"
              end
            end

            app_guid = app_guid(application_name_or_id)
            # extract the hostname and the domain name from the FQDN
            /(?<domain_host>([-\w]+\.)*)(?<domain_name>([-\w]+\.[-\w]+))/ =~ domain[:name]
            domain_host.chomp!('.') unless domain_host.nil?

            # finally build the response
            route_to_paasal_domain(create_cf_domain(app_guid, domain_name, domain_host))
          end

          def delete_domain(application_name_or_id, route_id)
            app_guid = app_guid(application_name_or_id)
            # remove route from the app
            delete_response = delete("/v2/apps/#{app_guid}/routes/#{route_id}", expects: [201, 400])
            if delete_response.status == 400
              cf_error = delete_response.body[:code]
              if cf_error == 1002
                fail Errors::AdapterResourceNotFoundError, 'Domain not found. '\
                  'CF context specific: Route does not exist or is not assigned with this application'
              else
                # delete failed with 400, but not due to invalid domain
                fail Errors::AdapterRequestError,
                     "#{delete_response.body[:description]} (#{cf_error} - #{delete_response.body[:error_code]})"
              end
            end

            # check route usage
            route_in_apps = get("/v2/routes/#{route_id}/apps").body
            return unless route_in_apps[:total_results] == 0

            # route is no longer needed, delete
            delete("/v2/routes/#{route_id}")
          end

          private

          def domain?(application_name_or_id, domain_name)
            app_guid = app_guid(application_name_or_id)
            domain_without_protocol = %r{([a-zA-Z]+://)?([-\.\w]*)}.match(domain_name)[2]
            assigned_routes = get("/v2/apps/#{app_guid}/routes").body
            assigned_routes[:resources].each do |route|
              route_domain = get(route[:entity][:domain_url]).body
              return true if "#{route[:entity][:host]}.#{route_domain[:entity][:name]}" == domain_without_protocol
            end
            false
          end

          def route_to_paasal_domain(route_resource)
            entity = route_resource[:entity]
            metadata = route_resource[:metadata]
            assigned_domain = get(entity[:domain_url]).body
            domain = { id: metadata[:guid], created_at: metadata[:created_at] }
            if metadata[:updated_at].to_s == ''
              domain[:updated_at] = metadata[:created_at]
            else
              domain[:updated_at] = metadata[:updated_at]
            end

            if entity[:host].to_s == ''
              domain[:name] = assigned_domain[:entity][:name]
            else
              domain[:name] = "#{entity[:host]}.#{assigned_domain[:entity][:name]}"
            end
            domain
          end

          def cf_domain(domain_name)
            %w(private shared).each do |domain_type|
              response = get("/v2/#{domain_type}_domains").body
              response[:resources].each do |domain|
                return domain if domain[:entity][:name] == domain_name
              end
            end
            nil
          end

          def cf_route(domain_guid, domain_host)
            # There is no way to check if a root domain (empty hostname) is already taken.
            # Therefore we must iterate through all routes and find matches...
            all_routes = get('/v2/routes').body[:resources]
            all_routes.each do |route|
              return route if route[:entity][:domain_guid] == domain_guid && route[:entity][:host] == domain_host
            end
            nil
          end

          def create_cf_domain(app_guid, domain_name, domain_host)
            created_domain = cf_domain(domain_name)
            unless created_domain
              # domain does not exist, create!
              domain_request_body = { name: domain_name, owning_organization_guid: default_organization_guid }
              created_domain = post('/v2/private_domains', body: domain_request_body).body
            end

            created_route = cf_route(created_domain[:metadata][:guid], domain_host)
            unless created_route
              # route does not exist, create!
              route_request_body =  { domain_guid: created_domain[:metadata][:guid],
                                      host: domain_host, space_guid: user_space_guid }
              created_route = post('/v2/routes', body: route_request_body).body
            end

            # assign the route to the application
            put("/v2/apps/#{app_guid}/routes/#{created_route[:metadata][:guid]}").body

            # return the actual route, not the association response
            created_route
          end
        end
      end
    end
  end
end
