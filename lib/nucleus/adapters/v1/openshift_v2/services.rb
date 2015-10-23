module Nucleus
  module Adapters
    module V1
      class OpenshiftV2 < Stub
        # Openshift V2, operations for the application's addons
        module Services
          # @see Stub#services
          def services
            embedded_cartridges.collect { |cartridge| to_nucleus_service(cartridge) }
          end

          # @see Stub#service
          def service(service_id)
            to_nucleus_service(embedded_cartridge(service_id))
          end

          # @see Stub#service_plans
          def service_plans(service_id)
            cartridge = embedded_cartridge(service_id)
            # Currently there are no plans, implement when required...
            return [default_plan(cartridge)] if cartridge[:usage_rates].empty?
            cartridge[:usage_rates].collect { |usage_rate| to_nucleus_plan(cartridge, usage_rate) }
          end

          # @see Stub#service_plan
          def service_plan(service_id, plan_id)
            cartridge = embedded_cartridge(service_id)
            if (cartridge[:usage_rates].empty? && plan_id != 'default') ||
               (!cartridge[:usage_rates].empty? && !cartridge[:usage_rates].any? { |rate| rate[:plan_id] == plan_id })
              # Currently there are no plans, implement when required...
              fail Errors::AdapterResourceNotFoundError, "No such service plan name '#{plan_id}' for service "\
                "'#{service_id}'"
            end

            return default_plan(cartridge) if cartridge[:usage_rates].empty?
            to_nucleus_plan(cartridge, cartridge[:usage_rates].find { |rate| rate[:plan_id] == plan_id })
          end

          # @see Stub#installed_services
          def installed_services(application_id)
            installed_cartridges(application_id).collect do |installed|
              to_nucleus_installed_service(installed)
            end
          end

          # @see Stub#installed_service
          def installed_service(application_id, service_id)
            installed = get("/application/#{app_id_by_name(application_id)}/cartridge/#{service_id}").body[:data]
            to_nucleus_installed_service(installed)
          end

          # @see Stub#add_service
          def add_service(application_id, service_entity, plan_entity)
            # make sure dependencies are installed
            app_id = app_id_by_name(application_id)
            begin
              service_to_add = embedded_cartridge(service_entity[:id])
            rescue Errors::AdapterResourceNotFoundError
              raise Errors::SemanticAdapterRequestError, "Invalid service: '#{service_entity[:id]}' could not be found"
            end
            # verify dependencies are installed, throws error if not
            verify_cartridge_dependencies(app_id, service_entity[:id], service_to_add)

            # check plan (if there are some)
            # no plans, chosen plan must be 'default'
            plan_name = service_to_add[:usage_rates].find { |plan| plan[:plan_id] == plan_entity[:id] }
            if (service_to_add[:usage_rates].empty? && plan_entity[:id] != 'default') ||
               (!service_to_add[:usage_rates].empty? && plan_name.nil?)
              fail Errors::SemanticAdapterRequestError, "No such service plan name '#{plan_entity[:id]}' for service "\
              "'#{service_entity[:id]}' and application '#{application_id}'"
            end

            # TODO: if a different plan than 'default' is chosen, we can't use it yet :/
            # However, only 'standalone' cartridges showed different plans as of April, 15th 2015
            to_nucleus_installed_service(post("/application/#{app_id}/cartridges",
                                              body: { cartridge: service_entity[:id] }).body[:data])
          end

          # @see Stub#remove_service
          def remove_service(application_id, service_id)
            delete("/application/#{app_id_by_name(application_id)}/cartridge/#{service_id}")
          end

          private

          def verify_cartridge_dependencies(application_id, service_id, service_to_add)
            missing_dependencies = service_to_add.key?(:requires) ? service_to_add[:requires] : []
            already_installed = installed_cartridges(application_id)
            already_installed.each { |installed_cartridge| missing_dependencies.delete(installed_cartridge[:name]) }
            fail Errors::SemanticAdapterRequestError, "Failed to add service '#{service_id}' for application "\
              "'#{application_id}'. The service's dependencies '#{missing_dependencies}' are not, "\
              'but have to be installed.' unless missing_dependencies.empty?
          end

          def installed_cartridges(application_id)
            installed = get("/application/#{app_id_by_name(application_id)}/cartridges").body[:data]
            installed.find_all do |cartridge|
              # exclude the 'haproxy' addon from the list. It is a core part of the application and can't be modified
              # exclude all standalone cartridges, we do not yet support them
              cartridge[:type] == 'embedded' && !cartridge[:name].start_with?('haproxy-')
            end
          end

          def embedded_cartridges
            get('/cartridges').body[:data].find_all { |cartridge| cartridge[:type] == 'embedded' }
          end

          def embedded_cartridge(service_id)
            get("/cartridge/#{service_id}").body[:data]
          end

          def to_nucleus_service(cartridge)
            # id, description and name is already contained
            cartridge[:required_services] = cartridge.key?(:requires) ? cartridge[:requires] : []
            cartridge[:documentation_url] = nil
            cartridge[:release] = cartridge[:version]
            cartridge[:free_plan] = cartridge[:usage_rates] == []
            cartridge[:created_at] = cartridge[:creation_time]
            cartridge[:updated_at] = cartridge[:creation_time]
            cartridge
          end

          def to_nucleus_installed_service(installed_service)
            installed_service = to_nucleus_service(installed_service)
            # Currently there are no plans, implement when required...
            installed_service[:active_plan] = 'default'
            installed_service[:properties] = installed_service.key?(:properties) ? installed_service[:properties] : []
            installed_service[:web_url] = nil
            installed_service
          end

          def to_nucleus_plan(cartridge, usage_rate)
            {
              id: usage_rate[:plan_id],
              name: usage_rate[:plan_id],
              description: nil,
              free: false,
              costs: [{
                # Openshift online currently bills in USD, EUR and CAD
                price: [{ amount: usage_rate[:cad], currency: 'CAD' },
                        { amount: usage_rate[:eur], currency: 'EUR' },
                        { amount: usage_rate[:usd], currency: 'USD' }],
                per_instance: false,
                period: usage_rate[:duration]
              }],
              created_at: cartridge[:creation_time],
              updated_at: cartridge[:creation_time]
            }
          end

          def default_plan(cartridge)
            {
              id: 'default',
              name: 'default',
              description: 'Default plan, cartridge does not offer different plans',
              free: true,
              costs: [{
                # Openshift online currently bills in USD, EUR and CAD
                price: [{ amount: 0.00, currency: 'CAD' },
                        { amount: 0.00, currency: 'EUR' },
                        { amount: 0.00, currency: 'USD' }],
                per_instance: false,
                period: 'hour'
              }],
              created_at: cartridge[:creation_time],
              updated_at: cartridge[:creation_time]
            }
          end
        end
      end
    end
  end
end
