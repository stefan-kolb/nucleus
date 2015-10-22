module Nucleus
  module Adapters
    module V1
      class OpenshiftV2 < Stub
        module Data
          # @see Stub#deploy
          def deploy(application_id, file, file_compression_format)
            app_id = app_id_by_name(application_id)
            app = get("/application/#{app_id}").body[:data]
            app_state = application_state(app)
            account = get('/user').body[:data]
            repo_name = "nucleus.app.repo.openshift_v2.deploy.#{application_id}.#{SecureRandom.uuid}"
            # clone, extract, push and finally delete cloned repository (sync)
            with_ssh_key do
              GitDeployer.new(repo_name, app[:git_url], account[:email]).deploy(file, file_compression_format)
            end

            # auto deployment could be active for applications not created with Nucleus
            return if app[:auto_deploy]

            build_deployment(app_id)

            return unless app_state == Enums::ApplicationStates::CREATED

            # and finally stop so we don't get to see the sample application and switch to the deployed state
            send_event(application_id, 'stop')
          end

          # @see Stub#download
          def download(application_id, compression_format)
            # Only possible with git
            app = get("/application/#{app_id_by_name(application_id)}").body[:data]
            if application_state(app) == Enums::ApplicationStates::CREATED
              fail Errors::SemanticAdapterRequestError, 'Application must be deployed before data can be downloaded'
            end
            # compress files to archive but exclude the .git repo
            repo_name = "nucleus.app.repo.openshift_v2.download.#{application_id}.#{SecureRandom.uuid}"
            with_ssh_key do
              GitDeployer.new(repo_name, app[:git_url], nil).download(compression_format, true)
            end
          end

          # @see Stub#rebuild
          def rebuild(application_id)
            app_id = app_id_by_name(application_id)
            app = get("/application/#{app_id}").body[:data]
            if application_state(app) == Enums::ApplicationStates::CREATED
              fail Errors::SemanticAdapterRequestError, 'Application must be deployed before data can be rebuild'
            end

            account = get('/user').body[:data]
            repo_name = "nucleus.app.repo.openshift_v2.rebuild.#{application_id}.#{SecureRandom.uuid}"

            with_ssh_key do
              GitDeployer.new(repo_name, app[:git_url], account[:email]).trigger_build
            end

            # if auto deployment ist disabled, we must also trigger a clean build
            build_deployment(app_id) unless app[:auto_deploy]

            # return with updated application
            application(application_id)
          end

          private

          def build_deployment(app_id)
            # deploy
            post("/application/#{app_id}/deployments", body: { force_clean_build: true })
          end

          def with_ssh_key
            # 409 Conflict:
            # - 120: SSH key with name #{name} already exists. Use a different name or delete conflicting key and retry
            # - 121: Given public key is already in use. Use different key or delete conflicting key and retry.

            # load ssh key into Openshift
            matches = nucleus_config.ssh.handler.public_key.match(/(.*)\s{1}(.*)\s{1}(.*)/)
            key_name = register_key(matches[1], matches[2])
            return yield
          ensure
            # unload ssh key, allow 404 if the key couldn't be registered at first
            delete("/user/keys/#{key_name}", expects: [200, 204, 404]) if key_name
          end

          def register_key(type, key)
            key_name = "nucleus-#{SecureRandom.uuid}"
            # ignore if the key was already assigned to a different name (status == 409 && exit_code == 121)
            post('/user/keys', body: { name: key_name, type: type, content: key }, expects: [201, 409])
            key_name
          end
        end
      end
    end
  end
end
