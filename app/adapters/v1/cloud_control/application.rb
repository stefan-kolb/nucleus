module Paasal
  module Adapters
    module V1
      class CloudControl < BaseAdapter
        module Application
          def applications
            response = get('/app')
            apps = []
            response.body.each do |application|
              apps << to_paasal_app(application, default_deployment(application[:name]))
            end
            apps
          end

          def application(application_id)
            response = get("/app/#{application_id}").body
            to_paasal_app(response, default_deployment(response[:name]))
          end

          def apply_buildpack(application)
            runtimes = application.delete(:runtimes)
            return unless runtimes
            if runtimes.length > 1
              fail Errors::PlatformSpecificSemanticError.new('cloudControl only allows 1 runtime per application',
                                                             422_600_1)
            end
            buildpack = find_runtime(runtimes[0])
            if native_runtime?(buildpack)
              application[:type] = buildpack
            else
              application[:type] = 'custom'
              application[:buildpack_url] = buildpack
            end
          end

          def create_application(application)
            if application.key? :region
              unless application[:region].casecmp('default') == 0
                fail Errors::AdapterRequestError, "Region '#{application[:region]}' does not exist at the endpoint"
              end
              # there is no region in cloudControl --> remove from request
              application.delete :region
            end

            apply_buildpack(application)

            # force the use of repository type 'git', unless overridden by the params
            default_params = { repository_type: 'git' }
            application = default_params.merge(application)

            # TODO: throws 415, unsupported media type
            create_app_response = post('/app', body: application).body

            # create the default deployment, name will automatically become 'default'
            created_deployment = post("/app/#{create_app_response[:name]}/deployment", body: { name: 'paasal' }).body
            to_paasal_app(create_app_response, created_deployment)
          end

          def update_application(_application_id, _application)
            # TODO: how shall we resolve that cc does not allow app modifications?
            # a) we don't, keep error
            # b) create new app and migrate other settings
            fail Errors::PlatformSpecificSemanticError.new('cloudControl does not allow to update applications.',
                                                           422_500_2)
          end

          def delete_application(application_id)
            # delete all deployments first
            deployments = get("/app/#{application_id}/deployment").body
            deployments.each do |deployment|
              deployment_name = /(\w+)\/(\w+)/.match(deployment[:name])[2]
              delete("/app/#{application_id}/deployment/#{deployment_name}")
            end
            delete("/app/#{application_id}")
          end
        end
      end
    end
  end
end
