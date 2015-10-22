module Nucleus
  module Adapters
    module V1
      class CloudControl < Stub
        module Scaling
          # @see Stub#scale
          def scale(application_id, instances)
            # update the number of instances on the application's deployment
            scale_response = put("/app/#{application_id}/deployment/#{NUCLEUS_DEPLOYMENT}",
                                 body: { min_boxes: instances }).body
            to_paasal_app(get("/app/#{application_id}").body, scale_response)
          end
        end
      end
    end
  end
end
