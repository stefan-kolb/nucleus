module Nucleus
  module Adapters
    module V1
      class OpenshiftV2 < Stub
        module Lifecycle
          # @see Stub#start
          def start(application_id)
            # if app is only deployed, we must first restore the latest deployment
            id = app_id_by_name(application_id)
            validate_start_requirements(id, 'start')
            to_nucleus_app(send_event(id, 'start'))
          end

          # @see Stub#stop
          def stop(application_id)
            id = app_id_by_name(application_id)
            unless deployed?(id)
              fail Errors::SemanticAdapterRequestError, 'Application must be deployed before it can be stopped'
            end
            to_nucleus_app(send_event(id, 'stop'))
          end

          # @see Stub#restart
          def restart(application_id)
            id = app_id_by_name(application_id)
            validate_start_requirements(id, 'restart')
            to_nucleus_app(send_event(id, 'restart'))
          end

          private

          def validate_start_requirements(id, action)
            state = application_state(get("/application/#{id}").body[:data])
            if state == Enums::ApplicationStates::DEPLOYED
              activate(id, latest_deployment(id)[:id])
            elsif state == Enums::ApplicationStates::CREATED
              fail Errors::SemanticAdapterRequestError, "Application must be deployed before it can be #{action}ed"
            end
          end

          def deployed?(application_id)
            app = get("/application/#{app_id_by_name(application_id)}").body[:data]
            application_state(app) != Enums::ApplicationStates::CREATED
          end

          # Send the event and trigger an action.
          # @return [Hash] Openshift application data
          def send_event(application_id, event, options = {})
            options[:event] = event
            post("/application/#{app_id_by_name(application_id)}/events", body: options).body[:data]
          end

          def activate(application_id, deployment_id)
            send_event(application_id, 'activate', deployment_id: deployment_id)
          end
        end
      end
    end
  end
end
