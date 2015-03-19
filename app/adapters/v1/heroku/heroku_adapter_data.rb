module Paasal
  module Adapters
    module V1
      module HerokuAdapterData
        def deploy(application_id, file, file_compression_format)
          app = get("/apps/#{application_id}").body
          account = get('/account').body
          repo_name = "paasal.app.repo.heroku.deploy.#{application_id}.#{SecureRandom.uuid}"
          # clone, extract, push and finally delete cloned repository (sync)
          GitDeployer.new(repo_name, app[:git_url], account[:email]).deploy(file, file_compression_format)

          return unless application_state(app) == API::Application::States::CREATED
          # instantly remove all initially added dynos to keep the 'deployed' state on first deployment
          log.debug 'state before deployment was \'created\', scale web to 0'
          scale_web(application_id, 0)
        end

        def download(application_id, compression_format)
          # Only possible with git, not with HTTP builds
          app = get("/apps/#{application_id}").body
          if application_state(app) == API::Application::States::CREATED
            fail Errors::SemanticAdapterRequestError, 'Application must be deployed before data can be downloaded'
          end
          # compress files to archive but exclude the .git repo
          repo_name = "paasal.app.repo.heroku.download.#{application_id}.#{SecureRandom.uuid}"
          GitDeployer.new(repo_name, app[:git_url], nil).download(compression_format, true)
        end

        def rebuild(application_id)
          app = get("/apps/#{application_id}").body
          if application_state(app) == API::Application::States::CREATED
            fail Errors::SemanticAdapterRequestError, 'Application must be deployed before data can be rebuild'
          end

          account = get('/account').body
          repo_name = "paasal.app.repo.heroku.rebuild.#{application_id}.#{SecureRandom.uuid}"

          GitDeployer.new(repo_name, app[:git_url], account[:email]).trigger_build

          # return with updated application
          application(application_id)
        end
      end
    end
  end
end
