module Paasal
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
            installed_services = with_authentication { adapter.installed_services(params[:application_id]) }
            present installed_services, with: Models::InstalledServices
          end

          desc 'Add a service to the application' do
            success Models::InstalledService
            failure [[200, 'Service bound to application', Models::InstalledService]
                    ].concat ErrorResponses.standard_responses
          end
          params do
            requires :service, type: Hash do
              # we only need the service id
              requires :all, using: Paasal::API::Models::Service.documentation.slice(:id)
            end
            requires :plan, type: Hash do
              # and the ID of the chosen plan
              requires :all, using: Paasal::API::Models::ServicePlan.documentation.slice(:id)
            end
          end
          post '/' do
            installed_service = with_authentication do
              adapter.add_service(params[:application_id], params[:service], params[:plan])
            end
            present installed_service, with: Models::InstalledService
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
              installed_service = with_authentication do
                adapter.installed_service(params[:application_id], params[:service_id])
              end
              present installed_service, with: Models::InstalledService
            end

            desc 'Change a service that is already applied to the application' do
              success Models::InstalledService
              failure [[200, 'Installed service changed', Models::InstalledService]
                      ].concat ErrorResponses.standard_responses
            end
            params do
              requires :plan, type: Hash do
                # the ID of the chosen plan
                requires :all, using: Paasal::API::Models::ServicePlan.documentation.slice(:id)
              end
            end
            patch '/' do
              installed_service = with_authentication do
                adapter.change_service(params[:application_id], params[:service_id], params[:plan])
              end
              present installed_service, with: Models::InstalledService
            end

            desc 'Remove a service from the application' do
              failure [[204, 'Service removed']].concat ErrorResponses.standard_responses
            end
            delete '/' do
              with_authentication { adapter.remove_service(params[:application_id], params[:service_id]) }
              # respond with 204 when entity is deleted (see rfc7231)
              status 204
            end
          end
        end # end of resource
      end
    end
  end
end
