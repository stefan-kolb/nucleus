module Nucleus
  module API
    module V1
      class ApplicationServices < Grape::API
        helpers SharedParamsHelper

        params do
          use :application_context
        end
        resource 'endpoints/:endpoint_id/applications/:application_id/services', desc: 'Application services',
                 swagger: { nested: false, name: 'application-services' } do
          desc 'List all services that are used by the application' do
            success Models::InstalledServices
            failure [[200, 'Installed services retrieved', Models::InstalledServices]
                    ].concat ErrorResponses.standard_responses
          end
          get '/' do
            present adapter.installed_services(params[:application_id]), with: Models::InstalledServices
          end

          desc 'Add a service to the application' do
            success Models::InstalledService
            failure [[200, 'Service bound to application', Models::InstalledService]
                    ].concat ErrorResponses.standard_responses
          end
          params do
            requires :service, type: Hash do
              # we only need the service id
              requires :all, using: Nucleus::API::Models::Service.documentation.slice(:id)
            end
            requires :plan, type: Hash do
              # and the ID of the chosen plan
              requires :all, using: Nucleus::API::Models::ServicePlan.documentation.slice(:id)
            end
          end
          post '/' do
            declared_params = declared(params, include_missing: false)
            service_params = declared_params[:service]
            plan_params = declared_params[:plan]

            # allow ALL values in the vendor specific section
            service_params.merge!(params[:service][:vendor_specific]) if params[:service].key?(:vendor_specific)
            plan_params.merge!(params[:plan][:vendor_specific]) if params[:plan].key?(:vendor_specific)

            present adapter.add_service(params[:application_id], service_params, plan_params),
                    with: Models::InstalledService
          end

          params do
            use :service_id
          end
          # regex to allow dots in the service id as path element (as required by the Openshift V2 names)
          resource ':service_id', requirements: { service_id: %r{[^\/]*} } do
            desc 'Retrieve a service that is used by the application' do
              success Models::InstalledService
              failure [[200, 'Installed service retrieved', Models::InstalledService]
                      ].concat ErrorResponses.standard_responses
            end
            get '/' do
              present adapter.installed_service(params[:application_id], params[:service_id]),
                      with: Models::InstalledService
            end

            desc 'Change a service that is already applied to the application' do
              success Models::InstalledService
              failure [[200, 'Installed service changed', Models::InstalledService]
                      ].concat ErrorResponses.standard_responses
            end
            params do
              requires :plan, type: Hash do
                # the ID of the chosen plan
                requires :all, using: Nucleus::API::Models::ServicePlan.documentation.slice(:id)
              end
            end
            patch '/' do
              declared_params = declared(params, include_missing: false)
              plan_params = declared_params[:plan]

              # allow ALL values in the vendor specific section
              plan_params.merge!(params[:plan][:vendor_specific]) if params[:plan].key?(:vendor_specific)

              present adapter.change_service(params[:application_id], params[:service_id], plan_params),
                      with: Models::InstalledService
            end

            desc 'Remove a service from the application' do
              failure [[204, 'Service removed']].concat ErrorResponses.standard_responses
            end
            delete '/' do
              adapter.remove_service(params[:application_id], params[:service_id])
              # respond with 204 when entity is deleted (see rfc7231)
              status 204
            end
          end
        end # end of resource
      end
    end
  end
end
