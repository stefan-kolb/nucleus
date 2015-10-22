module Nucleus
  module Adapters
    module V1
      class CloudFoundryV2 < Stub
        # Cloud Foundry, operations for the application's addons
        module Services
          # @see Stub#services
          def services
            get('/v2/services?inline-relations-depth=1').body[:resources].collect do |service|
              # show only services that are both, active and bindable
              next unless service[:entity][:active] && service[:entity][:bindable]
              to_paasal_service(service)
            end.compact
          end

          # @see Stub#service
          def service(service_id_or_name)
            service_guid = service_guid(service_id_or_name)
            to_paasal_service(get("/v2/services/#{service_guid}?inline-relations-depth=1").body)
          end

          # @see Stub#service_plans
          def service_plans(service_id_or_name)
            service_guid = service_guid(service_id_or_name)
            load_plans(service_guid).collect { |plan| to_paasal_plan(plan) }
          end

          # @see Stub#service_plan
          def service_plan(service_id_or_name, plan_id)
            service_guid = service_guid(service_id_or_name)
            plan_guid = plan_guid(service_guid, plan_id, Errors::AdapterResourceNotFoundError)
            to_paasal_plan(get("/v2/service_plans/#{plan_guid}").body)
          end

          # @see Stub#installed_services
          def installed_services(application_name_or_id)
            app_guid = app_guid(application_name_or_id)
            get("/v2/apps/#{app_guid}/service_bindings?inline-relations-depth=1").body[:resources].collect do |binding|
              to_paasal_installed_service(binding)
            end
          end

          # @see Stub#installed_service
          def installed_service(application_name_or_id, service_id_or_name)
            app_guid = app_guid(application_name_or_id)
            service_guid = service_guid(service_id_or_name)
            cf_binding = binding(app_guid, service_guid)
            # make sure there is a binding
            fail Errors::AdapterResourceNotFoundError,
                 "No such service '#{service_id_or_name}' for application '#{application_name_or_id}'" unless cf_binding
            to_paasal_installed_service(cf_binding)
          end

          # @see Stub#add_service
          def add_service(application_name_or_id, service_entity, plan_entity)
            app_guid = app_guid(application_name_or_id)
            service_guid = service_guid(service_entity[:id], Errors::SemanticAdapterRequestError)
            cf_service = load_allowed_service(service_entity, service_guid)

            # get the plan, throws 422 if the plan could not be found
            plan_guid = plan_guid(service_guid, plan_entity[:id])

            # create new service instance
            instance_request_body = { space_guid: user_space_guid, service_plan_guid: plan_guid,
                                      name: "#{cf_service[:entity][:label]}-#{application_name_or_id}-paasal" }
            cf_instance = post('/v2/service_instances', body: instance_request_body).body

            # bind the created service instance to the application
            binding_request_body = { service_instance_guid: cf_instance[:metadata][:guid], app_guid: app_guid }
            cf_binding = post('/v2/service_bindings', body: binding_request_body).body

            # created service presentation
            to_paasal_installed_service(cf_binding, cf_service, cf_instance)
          end

          # @see Stub#change_service
          def change_service(application_name_or_id, service_id, plan_entity)
            app_guid = app_guid(application_name_or_id)
            service_guid = service_guid(service_id)
            cf_service = get("/v2/services/#{service_guid}").body
            fail_with(:service_not_updateable, [service_id]) unless cf_service[:entity][:plan_updateable]

            cf_binding = binding(app_guid, service_guid)

            # get the plan, throws 422 if the plan could not be found
            plan_guid = plan_guid(service_guid, plan_entity[:id])
            cf_instance = put("/v2/service_instances/#{cf_binding[:entity][:service_instance_guid]}",
                              body: { service_plan_guid: plan_guid }).body
            to_paasal_installed_service(cf_binding, cf_service, cf_instance)
          end

          # @see Stub#remove_service
          def remove_service(application_name_or_id, service_id)
            app_guid = app_guid(application_name_or_id)
            service_guid = service_guid(service_id)
            # sadly we can't resolve the binding and instance from the service_id with ease
            # we therefore setup a chain to resolve the binding and instance from the active pla
            binding = binding(app_guid, service_guid)

            # now remove the binding from the application
            delete("/v2/apps/#{app_guid}/service_bindings/#{binding[:metadata][:guid]}", expects: [201])
            # and finally delete the service instance
            delete("/v2/service_instances/#{binding[:entity][:service_instance_guid]}")
          end

          private

          def load_allowed_service(service_entity, service_guid)
            begin
              cf_service = get("/v2/services/#{service_guid}").body
            rescue Errors::AdapterResourceNotFoundError
              # convert to semantic error with the service being a body, not a path entity
              raise Errors::SemanticAdapterRequestError,
                    "Invalid service: Could not find service with the ID '#{service_entity[:id]}'"
            end

            # must be active and bindable?
            # currently we focus only on bindable services
            fail_with(:service_not_bindable, [service_entity[:id]]) unless cf_service[:entity][:bindable]
            # service must be active, otherwise we can't create the instance
            fail_with(:service_not_active, [service_entity[:id]]) unless cf_service[:entity][:active]
            # service seems to be valid, return
            cf_service
          end

          def remove_all_services(app_guid)
            get("/v2/apps/#{app_guid}/service_bindings").body[:resources].collect do |binding|
              # remove the binding from the application
              delete("/v2/apps/#{app_guid}/service_bindings/#{binding[:metadata][:guid]}", expects: [201])
              # and delete the service instance to prevent orphans
              delete("/v2/service_instances/#{binding[:entity][:service_instance_guid]}")
            end
          end

          def service_guid(service_id_or_name, error_class = Errors::AdapterResourceNotFoundError)
            return service_id_or_name if guid?(service_id_or_name)
            # list all available services
            services = get('/v2/services').body[:resources]
            # find a match and use the service's guid
            service_match = services.find { |service| service[:entity][:label] == service_id_or_name }
            fail error_class,
                 "Invalid service: Could not find service with name '#{service_id_or_name}'" unless service_match
            service_match[:metadata][:guid]
          end

          def binding(app_guid, service_id)
            service_plans = get("/v2/services/#{service_id}/service_plans").body[:resources]
            service_plan_ids = service_plans.collect { |plan| plan[:metadata][:guid] }
            app_bindings = get("/v2/apps/#{app_guid}/service_bindings?inline-relations-depth=1").body[:resources]
            # the plan must be bound to the app via an instance
            app_bindings.find do |binding|
              service_plan_ids.include?(binding[:entity][:service_instance][:entity][:service_plan_guid])
            end
          end

          def plan_guid(service_id, plan_name_or_id, error_class = Errors::SemanticAdapterRequestError)
            return plan_name_or_id if guid?(plan_name_or_id)
            # list all plans for the service
            plans = get("/v2/services/#{service_id}/service_plans").body[:resources]
            # find a match and use the plan's guid
            plan_match = plans.find { |plan| plan[:entity][:name] == plan_name_or_id }
            fail error_class,
                 "Invalid plan: No such plan '#{plan_name_or_id}' for service '#{service_id}'" unless plan_match
            plan_match[:metadata][:guid]
          end

          def load_plans(service_id)
            get("/v2/services/#{service_id}/service_plans").body[:resources]
          end

          # Memoize this detection.
          # The information is not critical, but takes some time to evaluate.
          # Values are not expected to change often.
          def free_plan?(service_id, plans = nil)
            @free_plans ||= {}
            return @free_plans[service_id] if @free_plans.key?(service_id)
            plans = load_plans(service_id) unless plans
            @free_plans[service_id] = plans.any? { |plan| plan[:entity][:free] }
            @free_plans[service_id]
          end

          def to_paasal_plan(cf_plan)
            plan = cf_plan[:entity]
            plan[:id] = cf_plan[:metadata][:guid]
            plan[:created_at] = cf_plan[:metadata][:created_at]
            plan[:updated_at] = cf_plan[:metadata][:updated_at]
            plan[:costs] = []
            plan

            # TODO: determine prices for CF services
            # we know how IBM handles the costs, but can't determine the country
            # we know how Pivotal IO handles the costs
            # but what do the others???

            # extra = Oj.load(plan[:extra])
            # if plan[:free]
            #   plan[:costs] = { period: '', per_instance: false, price: { amount: 0.00, currency: nil} }
            # elsif endpoint_url.include?('pivotal.io')
            #   # show prices for Pivotal Web Services
            #   # see for an explanation: http://docs.pivotal.io/pivotalcf/services/catalog-metadata.html
            #   plan[:costs] = extra[:costs].collect do |cost|
            #     prices = cost[:amount].collect { |currency, amount| { currency: currency, amount: amount } }
            #     { per_instance: false, period: cost[:unit], price: prices }
            #   end
            # elsif endpoint_url.include?('bluemix.net')
            #   # show prices for IBM Bluemix
            # else
            #   # fallback, unknown CF system
            # end
          end

          def to_paasal_service(cf_service)
            service = cf_service[:entity]
            service = apply_metadata(service, cf_service)
            service[:name] = service.delete(:label)
            service[:release] = service.delete(:version)
            if cf_service[:entity].key?(:service_plans)
              # use preloaded plans if available
              service[:free_plan] = free_plan?(service[:id], cf_service[:entity][:service_plans])
            else
              service[:free_plan] = free_plan?(service[:id])
            end
            # CF does not have service dependencies
            service[:required_services] = service.delete(:requires)
            # description and documentation_url should already be set
            service
          end

          # Show the installed service. Therefore we need:<br>
          # <ul>
          # <li>the classic service for the basic information (version, name, ...)</li>
          # <li>the binding for the properties and metadata (id, timestamps, ...)</li>
          # <li>the bound instance for the active plan and web_url</li>
          # </ul>
          def to_paasal_installed_service(cf_binding, cf_service = nil, cf_instance = nil)
            # load if not provided
            cf_instance = load_instance(cf_binding) unless cf_instance
            cf_service = load_service(cf_instance) unless cf_service
            # load if not provided
            unless cf_service
              cf_service = get("/v2/service_plans/#{cf_instance[:entity][:service_plan_guid]}"\
                '?inline-relations-depth=1').body[:entity][:service]
            end

            # active_plan, web_url, properties
            service = to_paasal_service(cf_service)
            # use the metadata of the binding, is more future proof than instance metadata
            apply_metadata(service, cf_binding)
            service[:active_plan] = cf_instance[:entity][:service_plan_guid]
            service[:web_url] = cf_instance[:entity][:dashboard_url]
            service[:properties] = binding_properties(cf_binding)
            service
          end

          def load_instance(cf_binding)
            if cf_binding[:entity].key?(:service_instance)
              # use if nested property is available
              cf_binding[:entity][:service_instance]
            else
              get("/v2/service_instances/#{cf_binding[:entity][:service_instance_guid]}").body
            end
          end

          def load_service(cf_instance)
            get("/v2/service_plans/#{cf_instance[:entity][:service_plan_guid]}"\
              '?inline-relations-depth=1').body[:entity][:service]
          end

          def binding_properties(binding)
            # in the credentials there are information such as: hostname, username, password, license keys, ...
            binding[:entity][:credentials].collect do |key, value|
              { key: key, value: value, description: nil }
            end
          end

          def apply_metadata(apply_to, cf_object)
            apply_to[:id] = cf_object[:metadata][:guid]
            apply_to[:created_at] = cf_object[:metadata][:created_at]
            apply_to[:updated_at] = cf_object[:metadata][:updated_at]
            apply_to
          end
        end
      end
    end
  end
end
