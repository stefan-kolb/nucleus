module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        # cloud control, operations for the application's addons
        module Services
          # @see Stub#services
          def services
            get('/addon').body.collect { |cc_service| to_paasal_service(cc_service) }
          end

          # @see Stub#service
          def service(service_name)
            to_paasal_service(get("/addon/#{service_name}").body)
          end

          # @see Stub#service_plans
          def service_plans(service_name)
            get("/addon/#{service_name}").body[:options].collect { |plan| to_paasal_plan(plan) }
          end

          # @see Stub#service_plan
          def service_plan(service_name, plan_name)
            plan_name = plan_name?(plan_name) ? plan_name : "#{service_name}.#{plan_name}"
            plan = get("/addon/#{service_name}").body[:options].find do |cc_plan|
              cc_plan[:name] == plan_name
            end
            fail Errors::AdapterResourceNotFoundError,
                 "No such plan '#{plan_name}' for service '#{service_name}'" unless plan
            to_paasal_plan(plan)
          end

          # @see Stub#installed_services
          def installed_services(application_id)
            load_installed_addons(application_id).collect do |assignment|
              # ignore config and alias addons, for us they are core parts of the application
              next if %w(config.free alias.free).include?(assignment[:addon_option][:name])
              service = service(parse_service_name(assignment[:addon_option][:name]))
              to_paasal_installed_service(service, assignment)
            end.compact
          end

          # @see Stub#installed_service
          def installed_service(application_id, service_name)
            # we also require the installed plan to retrieve the service
            plan_name = active_plan(application_id, service_name)
            assignment = get("/app/#{application_id}/deployment/#{PAASAL_DEPLOYMENT}/addon/#{plan_name}").body
            installed_service = service(parse_service_name(assignment[:addon_option][:name]))
            to_paasal_installed_service(installed_service, assignment)
          end

          # @see Stub#add_service
          def add_service(application_id, service_entity, plan_entity)
            plan_name = plan_name?(plan_entity[:id]) ? plan_entity[:id] : "#{service_entity[:id]}.#{plan_entity[:id]}"
            created = post("/app/#{application_id}/deployment/#{PAASAL_DEPLOYMENT}/addon",
                           body: { addon: plan_name }).body
            to_paasal_installed_service(service(service_entity[:id]), created)
          end

          # @see Stub#change_service
          def change_service(application_id, service_id, plan_entity)
            plan_name = active_plan(application_id, service_id)
            fail Errors::SemanticAdapterRequestError,
                 "Plan '#{plan_entity[:id]}' is already active for service '#{service_id}' of application "\
                 "'#{application_id}'" if plan_name == plan_entity[:id]

            updated = put("/app/#{application_id}/deployment/#{PAASAL_DEPLOYMENT}/addon/#{plan_name}",
                          body: { addon: plan_entity[:id] }).body
            to_paasal_installed_service(service(service_id), updated)
          end

          # @see Stub#remove_service
          def remove_service(application_id, service_id)
            plan_name = active_plan(application_id, service_id)
            delete("/app/#{application_id}/deployment/#{PAASAL_DEPLOYMENT}/addon/#{plan_name}")
          end

          private

          def plan_name?(plan_name)
            parts = plan_name.split('.')
            # must have 2 parts and both must not be empty
            parts.length == 2 && parts.all { |part| part.length > 0 }
          end

          def parse_service_name(plan_name)
            parts = plan_name.split('.')
            fail Errors::SemanticAdapterRequestError, 'Invalid service plan name: Name must contain only one dot, '\
              "which separates the service and plan, e.g. 'mysql.free'" if parts.length != 2
            parts[0]
          end

          def load_installed_addons(application_id)
            get("/app/#{application_id}/deployment/#{PAASAL_DEPLOYMENT}/addon").body
          end

          def active_plan(application_id, service_id)
            all_installed = load_installed_addons(application_id)
            installed_service = all_installed.find do |service|
              service[:addon_option][:name].start_with?("#{service_id}.") || service[:addon_option][:name] == service_id
            end
            fail Errors::AdapterResourceNotFoundError,
                 "No such service '#{service_id}' for application '#{application_id}'" unless installed_service
            installed_service[:addon_option][:name]
          end

          def free_plan?(service)
            service[:options].any? { |plan| plan[:thirty_days_price].to_i == 0 }
          end

          # The currency that is used for the prices is not stored within the API.
          # However, we can identify the currency based on a list of known providers.
          # As fallback, we assume the currency is EURO.
          def currency
            return 'USD' if endpoint_url.to_s.include?('dotcloudapp.com')
            return 'CHF' if endpoint_url.to_s.include?('app.exo.io')
            # EUR used for cloudControl, CLOUD & HEAT and as fallback
            'EUR'
          end

          def to_paasal_plan(plan)
            plan[:id] = plan[:name]
            plan[:free] = plan[:thirty_days_price].to_i == 0
            plan[:description] = nil
            # TODO: extract payment period to enum
            plan[:costs] = [{ period: 'month', per_instance: plan[:price_is_per_box],
                             price: [amount: plan[:thirty_days_price].to_f, currency: currency] }]
            plan[:created_at] = nil
            plan[:updated_at] = nil
            plan
          end

          def to_paasal_service(service)
            service[:id] = service[:name]
            service[:release] = service.delete(:stage)
            # the API does not contain any information, but the homepage does
            service[:documentation_url] = "https://www.cloudcontrol.com/add-ons/#{service[:name]}"
            service[:description] = nil
            service[:created_at] = nil
            service[:updated_at] = nil
            service[:required_services] = []
            service[:free_plan] = free_plan?(service)
            service
          end

          def to_paasal_installed_service(service, installed_service)
            # settings ? ? ?
            service[:active_plan] = installed_service[:addon_option][:name]
            if installed_service[:settings] && !installed_service[:settings].empty?
              properties = installed_service[:settings].collect do |key, value|
                { key: key, value: value, description: nil }
              end
            end
            service[:properties] = properties ? properties : []
            service[:web_url] = nil
            service
          end
        end
      end
    end
  end
end
