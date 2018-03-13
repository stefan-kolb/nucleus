module Nucleus
  module Adapters
    module V1
      class Heroku < Stub
        module Application
          # @see Stub#applications
          def applications
            response = get('/apps')
            apps = []
            response.body.each do |application|
              apps << to_nucleus_app(application)
            end
            apps
          end

          # @see Stub#application
          def application(application_id)
            response = get("/apps/#{application_id}")
            to_nucleus_app response.body
          end

          # @see Stub#delete_application
          def delete_application(application_id)
            # returns the application, but we do not want any output
            delete("/apps/#{application_id}")
          end

          # @see Stub#create_application
          def create_application(application)
            # updates the application with a valid region identity
            retrieve_region(application)

            # Heroku does not support autoscale
            fail_with(:no_autoscale) if application[:autoscaled]
            application.delete :autoscaled

            # can fail if runtime URLs are invalid or names do not exist on this platform
            runtimes = runtimes_to_install(application)

            # create the actual application
            created_app = post('/apps', body: application).body

            # when application has been created, process runtime information if applicable
            unless runtimes.nil? || runtimes.empty?
              begin
                install_runtimes(created_app[:id], runtimes)
              rescue StandardError
                # if buildpack fails, make sure app gets deleted (!)
                log.debug 'Runtime installation failed, rollback...'
                delete_application(created_app[:id])
                log.debug '...application successfully rolled back'
                raise Errors::AdapterRequestError,
                      'Heroku requires a buildpack URL when the runtime shall be specified manually.'
              end
            end
            to_nucleus_app(created_app)
          end

          # TODO: make update transactional in case sub-task (app, buildpacks) fails
          # @see Stub#update_application
          def update_application(application_id, application)
            # start updating the buildpacks
            if application.key? :runtimes
              # can fail if runtime URLs are invalid or names do not exist on this platform
              runtimes = runtimes_to_install(application)
              install_runtimes(application_id, runtimes)
            end

            # now change the app name and all other direct properties, which are in the body
            response = patch("/apps/#{application_id}", body: application)
            to_nucleus_app(response.body)
          end

          private

          def to_nucleus_app(heroku_application)
            # load dynos only once
            dynos = dynos(heroku_application[:id])
            # add missing fields to the application representation
            heroku_application[:autoscaled] = false
            heroku_application[:state] = application_state(heroku_application, dynos)
            heroku_application[:instances] = application_instances(heroku_application[:id])
            heroku_application[:active_runtime] = heroku_application.delete(:buildpack_provided_description)
            heroku_application[:runtimes] = installed_buildpacks(heroku_application[:id])
            heroku_application[:release_version] = latest_release(heroku_application[:id], dynos)
            heroku_application[:region] = heroku_application[:region][:name]
            heroku_application
          end
        end
      end
    end
  end
end
