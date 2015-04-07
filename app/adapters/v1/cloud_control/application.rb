module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        # cloud control, CRUD operations for the application object
        module Application
          # @see Stub#applications
          def applications
            response = get('/app')
            apps = []
            response.body.each do |application|
              apps << to_paasal_app(application, default_deployment(application[:name]))
            end
            apps
          end

          # @see Stub#application
          def application(application_id)
            response = get("/app/#{application_id}").body
            to_paasal_app(response, default_deployment(response[:name]))
          end

          # @see Stub#create_application
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

            create_app_response = post('/app', body: application).body

            # create the default deployment, name will automatically become 'default'
            created_deployment = post("/app/#{create_app_response[:name]}/deployment", body: { name: 'paasal' }).body

            # activate the variables addon. However, the activation explicitly requires an initial key value pair...
            post("/app/#{create_app_response[:name]}/deployment/#{PAASAL_DEPLOYMENT}/addon",
                 body: { addon: 'config.free', options: "{\"paasal-initialized\": \"true\"}" }).body
            # ...now delete the initial key value pair to have the desired clean setup
            delete_env_var(create_app_response[:name], 'paasal-initialized')

            to_paasal_app(create_app_response, created_deployment)
          end

          # @see Stub#delete_application
          def delete_application(application_id)
            # delete all deployments first
            deployments = get("/app/#{application_id}/deployment").body
            deployments.each do |deployment|
              deployment_name = /(\w+)\/(\w+)/.match(deployment[:name])[2]
              delete("/app/#{application_id}/deployment/#{deployment_name}")
            end
            delete("/app/#{application_id}")
          end

          private

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
        end
      end
    end
  end
end
