module Paasal
  module Adapters
    module V1
      class CloudFoundryV2 < Stub
        # AppStates for Cloud Foundry V2, or the logic to determine the current application state
        module AppStates
          private

          def application_state(app_resource)
            if app_resource[:entity][:state] == 'STARTED'
              # 1: crashed
              return Enums::ApplicationStates::CRASHED if app_resource[:entity][:package_state] == 'FAILED'
              # 1: started
              return Enums::ApplicationStates::RUNNING if app_resource[:entity][:package_state] == 'STAGED'
            end

            # 4: stopped if there is a detected buildpack
            return Enums::ApplicationStates::STOPPED unless app_resource[:entity][:staging_task_id].nil?
            # 3: deployed if stopped but no data can be downloaded
            return Enums::ApplicationStates::DEPLOYED if deployed?(app_resource[:metadata][:guid])
            # 2: created if stopped and no buildpack detected
            Enums::ApplicationStates::CREATED
          end
        end
      end
    end
  end
end
