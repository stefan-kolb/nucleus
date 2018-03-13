module Nucleus
  module API
    module V1
      class Endpoints < Grape::API
        helpers SharedParamsHelper

        resource :endpoints, desc: 'Endpoint and Application operations' do
          # GET endpoint
          desc 'Get a selected endpoint entity via its ID' do
            success Models::Endpoint
            failure [[200, 'Endpoint retrieved', Models::Endpoint]].concat ErrorResponses.standard_responses
          end
          params do
            use :endpoint_id
          end
          get ':endpoint_id' do
            present load_endpoint, with: Models::Endpoint
          end

          desc 'Update an endpoint entity' do
            success Models::Endpoint
            failure [[200, 'Endpoint updated', Models::Endpoint]].concat ErrorResponses.standard_responses
          end
          params do
            use :endpoint_id
            requires :endpoint, type: Hash do
              optional :all, using: Nucleus::API::Models::Endpoint.documentation
                                                                  .except(:id, :applications, :created_at, :updated_at, :_links)
            end
          end
          patch ':endpoint_id' do
            # load the endpoint and verify it is valid
            endpoint = load_endpoint

            # :endpoint is required, therefore no check for the key is required
            update_fields(endpoint, Models::Endpoint.documentation, declared(params, include_missing: false)[:endpoint])

            # save the changes
            endpoint_dao.set endpoint
            present endpoint, with: Models::Endpoint
          end

          desc 'Delete an endpoint entity' do
            # empty response body, therefore no actual success message
            failure [[204, 'Endpoint deleted']].concat ErrorResponses.standard_responses
          end
          params do
            use :endpoint_id
          end
          delete ':endpoint_id' do
            endpoint = load_endpoint
            endpoint_dao.delete(params[:endpoint_id])
            # remove the endpoint from the provider
            provider = load_provider(provider_id: endpoint.provider)
            provider.endpoints.delete endpoint.id unless provider.endpoints.nil?
            provider_dao.set provider
            # respond with 204 when entity is deleted (see rfc7231)
            status 204
          end
        end # endpoint namespace
      end
    end
  end
end
