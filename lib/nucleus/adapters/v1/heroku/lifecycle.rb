module Nucleus
  module Adapters
    module V1
      class Heroku < Stub
        module Lifecycle
          # Lifecycle:
          # A) via maintenance - workers are still active
          # B) via formation - loose scaling information

          # @see Stub#start
          def start(application_id)
            log.debug "Start @ #{@endpoint_url}"

            app = application(application_id)
            if app[:state] == Enums::ApplicationStates::DEPLOYED
              # add web dyno if there currently are no dynos (state == deployed)
              scale_web(application_id, 1)
            elsif app[:state] == Enums::ApplicationStates::CREATED
              # fail if there is no deployment
              raise Errors::SemanticAdapterRequestError, 'Application must be deployed before it can be started'
            end

            scale_worker(application_id, 1)
            update_application(application_id, maintenance: false)
          end

          # @see Stub#stop
          def stop(application_id)
            log.debug "Stop @ #{@endpoint_url}"

            # fail if there is no deployment
            app = application(application_id)
            if app[:state] == Enums::ApplicationStates::CREATED
              raise Errors::SemanticAdapterRequestError, 'Application must be deployed before it can be stopped'
            end

            scale_worker(application_id, 0)
            update_application(application_id, maintenance: true)
          end

          # @see Stub#restart
          def restart(application_id)
            log.debug "Restart @ #{@endpoint_url}"
            stop(application_id)
            start(application_id)
          end
        end
      end
    end
  end
end
