module Paasal
  module Adapters
    module V1
      class OpenshiftV2 < Stub
        module Application
          def applications
            response = get('/applications')
            apps = []
            response.body[:data].each do |application|
              apps << application(application[:id])
            end
            apps
          end

          def application(application_id)
            app_response = get("/application/#{application_id}")
            app_gear_groups = get("/application/#{application_id}/gear_groups")
            to_paasal_app app_response.body[:data], app_gear_groups.body[:data]
          end

          def create_application(entity_hash)
            # TODO: implement me
          end

          def update_application(entity_id, entity_hash)
            # TODO: implement me
          end

          def delete_application(entity_id)
            # TODO: implement me
          end
        end
      end
    end
  end
end
