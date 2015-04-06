module Paasal
  module Adapters
    module V1
      class CloudFoundryV2 < Stub
        module Lifecycle
          # @see Stub#start
          def start(application_name_or_id)
            app_guid = app_guid(application_name_or_id)
            # fail if there is no deployment
            unless deployed?(app_guid)
              fail Errors::SemanticAdapterRequestError, 'Application must be deployed before it can be started'
            end

            # start by name or id
            start_response = put("/v2/apps/#{app_guid}", body: { state: 'STARTED' })
            to_paasal_app(start_response.body)
          end

          # @see Stub#stop
          def stop(application_name_or_id)
            app_guid = app_guid(application_name_or_id)
            # fail if there is no deployment
            unless deployed?(app_guid)
              fail Errors::SemanticAdapterRequestError, 'Application must be deployed before it can be stopped'
            end

            # stop by name or id
            stop_response = put("/v2/apps/#{app_guid}", body: { state: 'STOPPED' })
            to_paasal_app(stop_response.body)
          end

          # @see Stub#restart
          def restart(application_name_or_id)
            stop(application_name_or_id)
            start(application_name_or_id)
          end
        end
      end
    end
  end
end
