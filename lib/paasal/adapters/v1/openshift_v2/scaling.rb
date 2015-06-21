module Paasal
  module Adapters
    module V1
      class OpenshiftV2 < Stub
        module Scaling
          # @see Stub#scale
          def scale(application_id, instances)
            id = app_id_by_name(application_id)
            app = get("/application/#{id}").body[:data]
            fail_with(:not_scalable, [application_id]) unless app[:scalable]

            # check if scaling would exceed the available gears
            user = get('/user').body[:data]
            available_gears = user[:max_gears] - user[:consumed_gears]
            requires_additional_gears = instances - app[:gear_count]
            if requires_additional_gears > available_gears
              fail_with(:insufficient_gears, [application_id, instances, requires_additional_gears, available_gears])
            end

            # scale up if we require more gears
            while requires_additional_gears > 0
              send_event(id, 'scale-up')
              requires_additional_gears -= 1
            end

            # scale down if we have too much gears
            while requires_additional_gears < 0
              send_event(id, 'scale-down')
              requires_additional_gears += 1
            end

            # reload the app to see if all operations were taken into account
            application(id)
          end
        end
      end
    end
  end
end
