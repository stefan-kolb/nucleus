module Nucleus
  module Adapters
    module V1
      class CloudFoundryV2 < Stub
        module Application
          # @see Stub#applications
          def applications
            response = get('/v2/apps')
            apps = []
            response.body[:resources].each do |application_resource|
              apps << to_nucleus_app(application_resource)
            end
            apps
          end

          # @see Stub#application
          def application(application_name_or_id)
            app_guid = app_guid(application_name_or_id)
            get_response = get("/v2/apps/#{app_guid}")
            to_nucleus_app(get_response.body)
          end

          # @see Stub#create_application
          def create_application(application)
            if application.key? :region
              unless application[:region].casecmp('default') == 0
                raise Errors::SemanticAdapterRequestError,
                      "Region '#{application[:region]}' does not exist at the endpoint. "\
                      'Please check which regions are actually available on this endpoint.'
              end
              # there is no region in Cloud Foundry --> remove from request
              application.delete :region
            end

            apply_buildpack(application)

            # apply default values, if not overridden by custom params
            default_params = { space_guid: user_space_guid }
            application = default_params.merge(application)

            # WORKAROUND: requires numeric input, but rack-test provides characters :/
            application['memory'] = application['memory'].to_i if application.key?('memory')

            response = post('/v2/apps', body: application).body

            # now create the default route (similar to when using an UI, e.g. Pivotal, Stackato or Bluemix) == web_url
            create_cf_domain(response[:metadata][:guid], @endpoint_app_domain, response[:metadata][:guid])

            # finally build the application response
            application(response[:metadata][:guid])
          end

          # @see Stub#update_application
          def update_application(application_name_or_id, application_form)
            app_guid = app_guid(application_name_or_id)
            apply_buildpack(application_form)
            # update by guid
            update_response = put("/v2/apps/#{app_guid}", body: application_form)
            to_nucleus_app(update_response.body)
          end

          # @see Stub#delete_application
          def delete_application(application_name_or_id)
            app_guid = app_guid(application_name_or_id)
            # first delete all service bindings
            remove_all_services(app_guid)
            # then delete the default route (otherwise it would remain as orphaned route)
            routes = get("/v2/apps/#{app_guid}/routes?q=host:#{app_guid}&inline-relations-depth=1").body[:resources]
            default_route = routes.find { |route| route[:entity][:domain][:entity][:name] == @endpoint_app_domain }
            delete("/v2/routes/#{default_route[:metadata][:guid]}") if default_route
            # and finally delete the app
            delete("/v2/apps/#{app_guid}")
          end

          private

          def apply_buildpack(application)
            # handle desired runtime(s)
            runtimes = application.delete(:runtimes)
            return unless runtimes
            fail_with(:only_one_runtime) if runtimes.length > 1

            buildpack = find_runtime(runtimes[0])
            # use the translated buildpack name if available, otherwise pass on the given runtime name
            application[:buildpack] = buildpack ? buildpack : runtimes[0]
          end

          def to_nucleus_app(app_resource)
            metadata = app_resource[:metadata]
            app = app_resource[:entity]

            app[:id] = metadata[:guid]
            app[:created_at] = metadata[:created_at]
            app[:updated_at] = metadata[:updated_at] || metadata[:created_at]
            app[:state] = application_state(app_resource)
            app[:web_url] = "http://#{app_web_url(metadata[:guid])}"
            # route could have been deleted by the user
            app[:web_url] = nil unless domain?(metadata[:guid], app[:web_url])
            # Stackato does support autoscaling
            app[:autoscaled] = app.delete(:autoscale_enabled) || false
            app[:region] = 'default'
            app[:active_runtime] = app[:detected_buildpack]
            app[:runtimes] = app[:buildpack] ? [app[:buildpack]] : []
            app[:release_version] = app.delete(:version)
            app
          end
        end
      end
    end
  end
end
