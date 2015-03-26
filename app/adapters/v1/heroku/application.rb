module Paasal
  module Adapters
    module V1
      class Heroku < Stub
        module Application
          def applications
            response = get('/apps')
            apps = []
            response.body.each do |application|
              apps << to_paasal_app(application)
            end
            apps
          end

          def application(application_id)
            response = get("/apps/#{application_id}")
            to_paasal_app response.body
          end

          def delete_application(application_id)
            # returns the application, but we do not want any output
            delete("/apps/#{application_id}")
          end

          def create_application(application)
            # updates the application with a valid region identity
            retrieve_region(application)

            # Heroku does not support autoscale
            fail Errors::PlatformSpecificSemanticError, 'Can\'t use \'autoscale\' on Heroku' if application[:autoscaled]
            application.delete :autoscaled

            # can fail if runtime URLs are invalid or names do not exist on this platform
            runtimes = runtimes_to_install(application)

            # create the actual application
            created_app = post('/apps', body: application).body

            # when application has been created, process runtime information if applicable
            unless runtimes.nil? || runtimes.empty?
              begin
                install_runtimes(created_app[:id], runtimes)
              rescue
                # if buildpack fails, make sure app gets deleted (!)
                log.debug 'Runtime installation failed, rollback...'
                delete_application(created_app[:id])
                log.debug '...application successfully rolled back'
                raise Errors::AdapterRequestError,
                      'Heroku requires a buildpack URL when the runtime shall be specified manually.'
              end
            end
            to_paasal_app(created_app)
          end

          # TODO: make update transactional in case sub-task (app, buildpacks) fails
          def update_application(application_id, application)
            # start updating the buildpacks
            if application.key? :runtimes
              # can fail if runtime URLs are invalid or names do not exist on this platform
              runtimes = runtimes_to_install(application)
              install_runtimes(application_id, runtimes)
            end

            # now change the app name and all other direct properties, which are in the body
            response = patch("/apps/#{application_id}", body: application)
            to_paasal_app(response.body)
          end
        end
      end
    end
  end
end
