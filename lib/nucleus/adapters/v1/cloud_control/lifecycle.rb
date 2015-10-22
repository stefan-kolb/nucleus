module Nucleus
  module Adapters
    module V1
      class CloudControl < Stub
        module Lifecycle
          # @see Stub#start
          def start(application_id)
            deployment = default_deployment(application_id)
            # fail if there is no deployment
            unless data_uploaded?(deployment)
              fail Errors::SemanticAdapterRequestError, 'Application must be deployed before it can be started'
            end

            # if no cloudControl deployment has been made, trigger it
            if deployment[:version] == '-1'
              # deploy via the API, use version identifier -1 to refer a new build
              put("app/#{application_id}/deployment/#{NUCLEUS_DEPLOYMENT}", body: { version: '-1' })
            end

            # return the application object
            to_nucleus_app(get("/app/#{application_id}").body, default_deployment(application_id))
          end
        end
      end
    end
  end
end
