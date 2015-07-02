module Paasal
  module Adapters
    module V1
      class Heroku < Stub
        module Scaling
          # @see Stub#scale
          def scale(application_id, instances)
            scale_web(application_id, instances)
            # return the updated application object
            application(application_id)
          end

          private

          def scale_web(application_id, instances)
            patch("/apps/#{application_id}/formation", body: { updates: [{ process: 'web', quantity: instances }] })
          end

          def scale_worker(application_id, instances)
            patch("/apps/#{application_id}/formation", body: { updates: [{ process: 'worker', quantity: instances }] },
                  # raises 404 if no worker is defined in the Procfile
                  expects: [404])
          end
        end
      end
    end
  end
end
