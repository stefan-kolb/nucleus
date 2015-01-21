module Paasal
  module API
    module V1
      class Applications < Grape::API
        helpers Paasal::SharedParamsHelper

        resource :endpoints do

          # GET all applications behind an endpoint
          desc 'Get all applications that are registered at the endpoint' do
            success Paasal::API::Models::Applications
            failure ErrorResponses.standard_responses
          end
          params do
            use :endpoint_id
          end
          # TODO extract to use only once for all protected resources
          get ':endpoint_id/applications' do
            # TODO use endpoint for the adapter
            applications = repeat_adapter_call_on_invalid_authentication_cache do
              adapter.applications
            end

            present applications, with: Models::Applications
          end

        end

      end
    end
  end
end
