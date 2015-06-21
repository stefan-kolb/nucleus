module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        # cloud control data management operations
        module Data
          # @see Stub#deploy
          def deploy(application_id, file, compression_format)
            # get deployment, also serves as 404 check for application
            deployment = default_deployment(application_id)
            current_state = application_state(deployment)

            user = get('/user').body[0]
            name = "paasal.app.repo.cloudControl.deploy.#{application_id}.#{SecureRandom.uuid}"
            # push to the deployment branch, here: paasal
            with_ssh_key do
              deployer = GitDeployer.new(name, deployment[:branch], user[:email], PAASAL_DEPLOYMENT)
              deployer.deploy(file, compression_format)
            end

            return if current_state == API::Enums::ApplicationStates::CREATED ||
                      current_state == API::Enums::ApplicationStates::DEPLOYED

            # Deploy via the API, use version identifier -1 to refer a new build,
            # but ONLY (!) if the application is not in the CREATED or DEPLOYED state
            put("app/#{application_id}/deployment/#{PAASAL_DEPLOYMENT}", body: { version: '-1' })
          end

          # @see Stub#download
          def download(application_id, compression_format)
            # get deployment, also serves as 404 check for application
            deployment = default_deployment(application_id)
            if application_state(deployment) == API::Enums::ApplicationStates::CREATED
              fail Errors::SemanticAdapterRequestError, 'Application must be deployed before data can be downloaded'
            end

            # compress files to archive but exclude the .git repo
            name = "paasal.app.repo.cloudControl.download.#{application_id}.#{SecureRandom.uuid}"
            with_ssh_key do
              GitDeployer.new(name, deployment[:branch], nil, PAASAL_DEPLOYMENT).download(compression_format, true)
            end
          end

          # @see Stub#rebuild
          def rebuild(application_id)
            # get deployment, also serves as 404 check for application
            deployment = default_deployment(application_id)
            if application_state(deployment) == API::Enums::ApplicationStates::CREATED
              fail Errors::SemanticAdapterRequestError, 'Application must be deployed before data can be rebuild'
            end

            user = get('/user').body[0]
            name = "paasal.app.repo.cloudControl.rebuild.#{application_id}.#{SecureRandom.uuid}"

            with_ssh_key do
              GitDeployer.new(name, deployment[:branch], user[:email], PAASAL_DEPLOYMENT).trigger_build
            end

            # now deploy via the API, use version identifier -1 to refer a new build
            put("app/#{application_id}/deployment/#{PAASAL_DEPLOYMENT}", body: { version: '-1' })

            # return with updated application
            application(application_id)
          end

          private

          def register_key(user, type, key)
            key_name = "paasal-#{SecureRandom.uuid}"
            post("/user/#{user}/key", body: { key: [type, key, key_name].join(' ') }).body[:key_id]
          end
        end
      end
    end
  end
end
