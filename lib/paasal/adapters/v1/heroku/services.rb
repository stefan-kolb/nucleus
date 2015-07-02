module Paasal
  module Adapters
    module V1
      class Heroku < Stub
        module Services
          # @see Stub#services
          def services
            get('/addon-services').body.collect { |service| to_paasal_service(service) }
          end

          # @see Stub#service
          def service(service_id)
            to_paasal_service(get("/addon-services/#{service_id}").body)
          end

          # @see Stub#service_plans
          def service_plans(service_id)
            load_plans(service_id).collect { |plan| to_paasal_plan(plan) }.sort do |plan_1, plan_2|
              # only compare the first cost, covers most cases and sorting for all costs would be far too complex
              plan_1[:costs][0][:price].first[:amount].to_f <=> plan_2[:costs][0][:price].first[:amount].to_f
            end
          end

          # @see Stub#service_plan
          def service_plan(service_id, plan_id)
            to_paasal_plan(get("/addon-services/#{service_id}/plans/#{plan_id}").body)
          end

          # @see Stub#installed_services
          def installed_services(application_id)
            get("/apps/#{application_id}/addons").body.collect { |service| to_paasal_installed_service(service) }
          end

          # @see Stub#installed_service
          def installed_service(application_id, service_id)
            assigned_service = raw_installed_service(application_id, service_id)
            to_paasal_installed_service(assigned_service)
          end

          # @see Stub#add_service
          def add_service(application_id, service_entity, plan_entity)
            begin
              # make sure plan belongs to this service, throws 404 if no such plan
              # the service plan itself requires the name, e.g. 'sandbox' or the UUID
              service_plan(service_entity[:id], plan_entity[:id])
            rescue Errors::AdapterResourceNotFoundError => e
              # convert to 422
              raise Errors::SemanticAdapterRequestError, e.message
            end
            # the plan to choose requires the UUID of the plan OR the combination of both names
            plan_id = service_plan_identifier(service_entity[:id], plan_entity[:id])
            created = post("/apps/#{application_id}/addons", body: { plan: plan_id }).body
            to_paasal_installed_service(created)
          end

          # @see Stub#change_service
          def change_service(application_id, service_id, plan_entity)
            # make sure service is bound to the application
            assignment_id = raw_installed_service(application_id, service_id)[:id]
            begin
              # make sure plan belongs to this service, throws 404 if no such plan
              # the service plan itself requires the name, e.g. 'sandbox' or the UUID
              service_plan(service_id, plan_entity[:id])
            rescue Errors::AdapterResourceNotFoundError => e
              # convert to 422
              raise Errors::SemanticAdapterRequestError, e.message
            end
            # the plan to choose requires the UUID of the plan OR the combination of both names
            plan_id = service_plan_identifier(service_id, plan_id)
            updated = patch("/apps/#{application_id}/addons/#{assignment_id}", body: { plan: plan_id }).body
            to_paasal_installed_service(updated)
          end

          # @see Stub#remove_service
          def remove_service(application_id, service_id)
            # make sure service is bound to the application
            assignment_id = raw_installed_service(application_id, service_id)[:id]
            delete("/apps/#{application_id}/addons/#{assignment_id}")
          end

          private

          def service_plan_identifier(service_id, plan_id)
            # process plan id_or_name to build the unique identifier
            # a) is a UUID
            return plan_id if Regexp::UUID_PATTERN =~ plan_id
            # b) is valid identifier, contains ':'
            return plan_id if /^[-\w]+:[-\w]+$/i =~ plan_id
            # c) fetch id for name
            return "#{service_id}:#{plan_id}" unless Regexp::UUID_PATTERN =~ service_id
            # arriving here, service_id is UUID but plan_id is the name --> DOH!
            # we return the plan_id and the request will presumably fail
            plan_id
          end

          def raw_installed_service(application_id, service_id)
            # here we probably receive the ID of the service, not the service assignment ID itself
            installed = get("/apps/#{application_id}/addons/#{service_id}", expects: [200, 404])
            if installed.status == 404
              assignment_id = service_assignment_id(application_id, service_id)
              fail Errors::AdapterResourceNotFoundError,
                   "Service #{service_id} is not assigned to application #{application_id}" unless assignment_id
              return get("/apps/#{application_id}/addons/#{assignment_id}").body
            end
            installed.body
          end

          def service_assignment_id(application_id, service_id)
            all_services = get("/apps/#{application_id}/addons").body
            match = all_services.find do |addon|
              addon[:addon_service][:id] == service_id || addon[:addon_service][:name] == service_id
            end
            return match[:id] if match
            nil
          end

          def to_paasal_service(service)
            service[:description] = service.delete(:human_name)
            service[:release] = service.delete(:state)
            service[:required_services] = []
            service[:free_plan] = free_plan?(service[:id])
            service[:documentation_url] = "https://addons.heroku.com/#{service[:name]}"
            service
          end

          def to_paasal_installed_service(installed_service)
            service = service(installed_service[:addon_service][:id])
            # get all variables and reject all that do not belong to the addon
            unless installed_service[:config_vars].nil? && installed_service[:config_vars].empty?
              vars = get("/apps/#{installed_service[:app][:id]}/config-vars").body
              # ignore all vars that do not belong to the service
              vars = vars.delete_if { |k| !installed_service[:config_vars].include?(k.to_s) }
              # format to desired format
              vars = vars.collect { |k, v| { key: k, value: v, description: nil } }
            end
            service[:properties] = vars ? vars : []
            service[:active_plan] = installed_service[:plan][:id]
            service[:web_url] = installed_service[:web_url]
            service
          end

          def to_paasal_plan(plan)
            # TODO: extract payment period to enum
            plan[:costs] = [{ price: [amount: plan[:price][:cents] / 100.0, currency: 'USD'],
                             period: plan[:price][:unit], per_instance: false }]
            plan[:free] = plan[:price][:cents] == 0
            plan
          end

          def load_plans(service_id)
            get("/addon-services/#{service_id}/plans").body
          end

          # Memoize this detection.
          # The information is not critical, but takes some time to evaluate.
          # Values are not expected to change often.
          def free_plan?(service_id, plans = nil)
            @free_plans ||= {}
            return @free_plans[service_id] if @free_plans.key?(service_id)
            plans = load_plans(service_id) unless plans
            @free_plans[service_id] = plans.any? { |plan| plan[:price][:cents] == 0 }
            @free_plans[service_id]
          end
        end
      end
    end
  end
end
