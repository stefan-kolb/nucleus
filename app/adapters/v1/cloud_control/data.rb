module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        module Data
          def deploy(application_id, file, compression_format)
            deployment = default_deployment(application_id)
            account = get('/user').body[0]
            repo_name = "paasal.app.repo.cloudControl.deploy.#{application_id}.#{SecureRandom.uuid}"
            # clone, extract, push and finally delete cloned repository (sync)

            # push to the deployment branch, here: paasal
            GitDeployer.new(repo_name, deployment[:branch], account[:email], 'paasal').deploy(file, compression_format)

            # TODO: now deploy via the API

            # TODO: how to stop the application?
          end

          def download(application_id, compression_format)
            # TODO: get deployment state
            if application_state(app) == API::Models::Application::States::CREATED
              fail Errors::SemanticAdapterRequestError, 'Application must be deployed before data can be downloaded'
            end

            # compress files to archive but exclude the .git repo
            repo_name = "paasal.app.repo.cloudControl.download.#{application_id}.#{SecureRandom.uuid}"
            GitDeployer.new(repo_name, app[:git_url], nil, 'paasal').download(compression_format, true)
          end

          def rebuild(application_id)
            # TODO: get deployment state
            app = get("/apps/#{application_id}").body
            if application_state(app) == API::Models::Application::States::CREATED
              fail Errors::SemanticAdapterRequestError, 'Application must be deployed before data can be rebuild'
            end

            account = get('/user').body[0]
            repo_name = "paasal.app.repo.cloudControl.rebuild.#{application_id}.#{SecureRandom.uuid}"

            GitDeployer.new(repo_name, app[:git_url], account[:email], 'paasal').trigger_build

            # TODO: now deploy via the API

            # return with updated application
            application(application_id)
          end
        end
      end
    end
  end
end
