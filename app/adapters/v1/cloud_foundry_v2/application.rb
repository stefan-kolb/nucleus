module Paasal
  module Adapters
    module V1
      class CloudFoundryV2 < Stub
        module Application
          def applications
            response = get('/v2/apps')
            apps = []
            response.body[:resources].each do |application_resource|
              apps << to_paasal_app(application_resource)
            end
            apps
          end

          def application(application_name_or_id)
            app_guid = app_guid(application_name_or_id)
            get_response = get("/v2/apps/#{app_guid}")
            to_paasal_app(get_response.body)
          end

          def create_application(application)
            if application.key? :region
              unless application[:region].casecmp('default') == 0
                fail Errors::PlatformSpecificSemanticError,
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

            # now create the default route (similar to when using an UI, either Stackato or Bluemix) == web_url
            create_cf_domain(response[:metadata][:guid], @endpoint_app_domain, response[:metadata][:guid])

            # finally build the application response
            application(response[:metadata][:guid])
          end

          def update_application(application_name_or_id, application_form)
            app_guid = app_guid(application_name_or_id)
            apply_buildpack(application_form)
            # update by guid
            update_response = put("/v2/apps/#{app_guid}", body: application_form)
            to_paasal_app(update_response.body)
          end

          def delete_application(application_name_or_id)
            delete_response = delete("/v2/apps/#{application_name_or_id}", expects: [204, 404])
            return unless delete_response.status == 404
            found_guid = find_app_id_by_name(application_name_or_id, delete_response)
            delete("/v2/apps/#{found_guid}", expects: 204)
          end

          private

          def apply_buildpack(application)
            # handle desired runtime(s)
            runtimes = application.delete(:runtimes)
            return unless runtimes
            if runtimes.length > 1
              fail Errors::PlatformSpecificSemanticError.new('Cloud Foundry only allows 1 runtime per application',
                                                             422_500_1)
            end

            buildpack = find_runtime(runtimes[0])
            # use the translated buildpack name if available, otherwise pass on the given runtime name
            application[:buildpack] = buildpack ? buildpack : runtimes[0]
          end
        end
      end
    end
  end
end
