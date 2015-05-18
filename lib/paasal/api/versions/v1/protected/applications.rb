module Paasal
  module API
    module V1
      class Applications < Grape::API
        helpers SharedParamsHelper

        resource 'endpoints/:endpoint_id/applications', desc: 'Endpoint\'s applications',
                 swagger: { name: 'applications', nested: false } do
          desc 'Get all applications that are registered at the endpoint' do
            success Models::Applications
            failure ErrorResponses.standard_responses
          end
          params do
            use :endpoint_id
          end
          get '/' do
            present adapter.applications, with: Models::Applications
          end

          desc 'Get an applications that is registered at the endpoint' do
            success Models::Application
            failure [[200, 'Application retrieved', Models::Application]].concat ErrorResponses.standard_responses
          end
          params do
            use :application_context
          end
          get ':application_id' do
            present adapter.application(params[:application_id]), with: Models::Application
          end

          desc 'Delete an applications that is registered at the endpoint' do
            failure [[204, 'Application deleted']].concat ErrorResponses.standard_responses
          end
          params do
            use :application_context
          end
          delete ':application_id' do
            adapter.delete_application(params[:application_id])
            # respond with 204 when entity is deleted (see rfc7231)
            status 204
          end

          desc 'Create an applications to be registered at the endpoint' do
            success Models::Application
            failure [[201, 'Application created', Models::Application]].concat ErrorResponses.standard_responses
          end
          params do
            use :endpoint_id
            # require the keys of the application in the json object 'application'
            requires :application, type: Hash do
              # name is required, but we must use :all to get the presence validator. Name is selected via :using
              requires :all, using: Paasal::API::Models::Application.documentation.slice(:name)
              requires :runtimes, Paasal::API::Models::Application.documentation[:runtimes].merge(type: Array[String])
              # everything else is optional
              optional :all, using: Paasal::API::Models::Application.documentation.slice(:region, :autoscaled)
            end
          end
          post '/' do
            application_params = declared(params, include_missing: false)[:application]
            # allow ALL values in the vendor specific section
            if params[:application].key? :vendor_specific
              application_params = application_params.merge params[:application][:vendor_specific]
            end
            present adapter.create_application(application_params), with: Models::Application
          end

          desc 'Update an applications that is registered at the endpoint' do
            success Models::Application
            failure [[200, 'Application updated', Models::Application]].concat ErrorResponses.standard_responses
          end
          params do
            use :application_context
            # require the keys of the application in the json object 'application'
            requires :application, type: Hash do
              optional :name, Paasal::API::Models::Application.documentation[:name]
              optional :runtimes, Paasal::API::Models::Application.documentation[:runtimes].merge(type: Array[String])
            end
          end
          patch '/:application_id' do
            application_params = declared(params, include_missing: false)[:application]
            # allow ALL values in the vendor specific section
            if params[:application].key? :vendor_specific
              application_params = application_params.merge params[:application][:vendor_specific]
            end
            present adapter.update_application(params[:application_id], application_params), with: Models::Application
          end
        end
      end
    end
  end
end
