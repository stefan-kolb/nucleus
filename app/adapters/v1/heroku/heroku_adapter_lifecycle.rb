module Paasal
  module Adapters
    module V1
      module HerokuAdapterLifecycle
        # Lifecycle:
        # A) via maintenance - workers are still active
        # B) via formation - loose scaling information

        def start(application_id)
          log.debug "Start @ #{@endpoint_url}"

          app = application(application_id)
          if app[:state] == API::Application::States::DEPLOYED
            # add web dyno if there currently are no dynos (state == deployed)
            scale_web(application_id, 1)
          elsif app[:state] == API::Application::States::CREATED
            # fail if there is no deployment
            fail Errors::SemanticAdapterRequestError, 'Application must be deployed before it can be started'
          end

          scale_worker(application_id, 1)
          update_application(application_id, maintenance: false)
        end

        def stop(application_id)
          log.debug "Stop @ #{@endpoint_url}"

          # fail if there is no deployment
          app = application(application_id)
          if app[:state] == API::Application::States::CREATED
            fail Errors::SemanticAdapterRequestError, 'Application must be deployed before it can be stopped'
          end

          scale_worker(application_id, 0)
          update_application(application_id, maintenance: true)
        end

        def restart(application_id)
          log.debug "Restart @ #{@endpoint_url}"
          stop(application_id)
          start(application_id)
        end
      end
    end
  end
end
