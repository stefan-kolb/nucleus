module Paasal
  module Adapters
    module V1
      class Heroku < Stub
        module Data
          # @see Stub#deploy
          def deploy(application_id, file, file_compression_format)
            app = get("/apps/#{application_id}").body
            account = get('/account').body
            repo_name = "paasal.app.repo.heroku.deploy.#{application_id}.#{SecureRandom.uuid}"
            # clone, extract, push and finally delete cloned repository (sync)
            with_ssh_key do
              GitDeployer.new(repo_name, app[:git_url], account[:email]).deploy(file, file_compression_format)
            end

            return unless application_state(app) == Enums::ApplicationStates::CREATED
            # instantly remove all initially added dynos to keep the 'deployed' state on first deployment
            log.debug 'state before deployment was \'created\', scale web to 0'
            scale_web(application_id, 0)
          end

          # @see Stub#download
          def download(application_id, compression_format)
            # Only possible with git, not with HTTP builds
            app = get("/apps/#{application_id}").body
            if application_state(app) == Enums::ApplicationStates::CREATED
              fail Errors::SemanticAdapterRequestError, 'Application must be deployed before data can be downloaded'
            end
            # compress files to archive but exclude the .git repo
            repo_name = "paasal.app.repo.heroku.download.#{application_id}.#{SecureRandom.uuid}"
            with_ssh_key do
              GitDeployer.new(repo_name, app[:git_url], nil).download(compression_format, true)
            end
          end

          # @see Stub#rebuild
          def rebuild(application_id)
            app = get("/apps/#{application_id}").body
            if application_state(app) == Enums::ApplicationStates::CREATED
              fail Errors::SemanticAdapterRequestError, 'Application must be deployed before data can be rebuild'
            end

            account = get('/account').body
            repo_name = "paasal.app.repo.heroku.rebuild.#{application_id}.#{SecureRandom.uuid}"

            with_ssh_key do
              GitDeployer.new(repo_name, app[:git_url], account[:email]).trigger_build
            end

            # return with updated application
            application(application_id)
          end

          private

          def with_ssh_key
            # load ssh key into cloud control
            matches = nucleus_config.ssh.handler.public_key.match(/(.*)\s{1}(.*)\s{1}(.*)/)
            key_id = register_key(matches[1], matches[2])
            return yield
          ensure
            # unload ssh key, allow 404 if the key couldn't be registered at first
            delete("/account/keys/#{key_id}") if key_id
          end

          def register_key(type, key)
            # skip if the key is already registered
            installed_keys = get('/account/keys').body
            return nil if installed_keys.any? { |installed_key| installed_key[:public_key].include?(key) }

            key_name = "paasal-#{SecureRandom.uuid}"
            post('/account/keys', body: { public_key: [type, key, key_name].join(' ') }).body[:id]
          end
        end
      end
    end
  end
end
