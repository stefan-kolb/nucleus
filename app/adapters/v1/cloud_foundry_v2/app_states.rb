module Paasal
  module Adapters
    module V1
      class CloudFoundryV2 < Stub
        module AppStates
          def application_state(app_resource)
            if app_resource[:entity][:state] == 'STARTED'
              # 1: crashed
              return API::Models::Application::States::CRASHED if app_resource[:entity][:package_state] == 'FAILED'
              # 1: started
              return API::Models::Application::States::RUNNING if app_resource[:entity][:package_state] == 'STAGED'
            end

            # 4: stopped if there is a detected buildpack
            return API::Models::Application::States::STOPPED unless app_resource[:entity][:staging_task_id].nil?
            # 3: deployed if stopped but no data can be downloaded
            return API::Models::Application::States::DEPLOYED if deployed?(app_resource[:metadata][:guid])
            # 2: created if stopped and no buildpack detected
            API::Models::Application::States::CREATED
          end
        end
      end
    end
  end
end
