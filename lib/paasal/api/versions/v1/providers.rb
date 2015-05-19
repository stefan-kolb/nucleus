module Paasal
  module API
    module V1
      class Providers < Grape::API
        helpers SharedParamsHelper

        helpers do
          # noinspection RubyArgCount
          params :provider_id do
            requires :provider_id, type: String, desc: "The provider's ID"
          end
        end

        resource :providers do
          # GET provider
          desc 'Get a selected provider entity via its ID' do
            success Models::Provider
            failure [[200, 'Provider retrieved', Models::Provider]].concat ErrorResponses.standard_responses
          end
          params do
            use :provider_id
          end
          get ':provider_id' do
            provider = load_provider
            provider.endpoints = endpoint_dao.get_collection(provider.endpoints)
            present provider, with: Models::Provider
          end

          # GET a provider's endpoints
          desc 'Get all endpoints that are offered by this provider' do
            success Models::Endpoints
            failure [[200, 'Endpoints retrieved', Models::Endpoints]].concat ErrorResponses.standard_responses
          end
          params do
            use :provider_id
          end
          get ':provider_id/endpoints' do
            provider = load_provider
            endpoints = endpoint_dao.get_collection(provider.endpoints)
            present endpoints, with: Models::Endpoints
          end

          desc 'Create a new endpoint entity that belongs to this provider' do
            success Models::Endpoint
            failure [[201, 'Endpoint created', Models::Endpoint]].concat ErrorResponses.standard_responses
            headers(Location: { description: 'Link to the created entity', required: true })
          end
          params do
            use :provider_id
            # require the keys of the endpoint in the json object 'endpoint'
            requires :endpoint, type: Hash do
              # both are optional
              optional :all, using: Paasal::API::Models::Endpoint.documentation.slice(:app_domain, :trust)
              requires :all, using: Paasal::API::Models::Endpoint.documentation
                .except(:id, :app_domain, :trust, :applications, :created_at, :updated_at, :_links)
            end
          end
          post ':provider_id/endpoints' do
            # load the vendor and verify it is valid
            provider = load_provider
            # If validation passed, all required fields are available and not null (unless explicitly allowed).
            # Fields that were not allowed (id, ...) are excluded via declared(params)
            endpoint = Endpoint.new declared(params)[:endpoint]
            endpoint.provider = provider.id
            # automatically assigns a unique ID, but the name does not have to be unique
            endpoint_dao.set endpoint
            # finally assign the endpoint to the provider's collection and present the created entity
            provider.endpoints << endpoint.id
            provider_dao.set provider
            # add location header that refers to the created entity (see RFC7231 p.68)
            header 'Location', link_generator.resource(%w(endpoints), endpoint.id)
            present endpoint, with: Models::Endpoint
          end

          desc 'Update a provider entity' do
            success Models::Provider
            failure [[200, 'Provider updated', Models::Provider]].concat ErrorResponses.standard_responses
          end
          params do
            use :provider_id
            requires :provider, type: Hash do
              optional :all, using: Paasal::API::Models::Provider.documentation
                .except(:id, :endpoints, :vendor, :created_at, :updated_at, :_links)
            end
          end
          patch ':provider_id' do
            # load the endpoint and verify it is valid
            provider = load_provider

            # :provider is required, therefore no check for the key is required
            update_fields(provider, Models::Provider.documentation, declared(params, include_missing: false)[:provider])

            # save the changes
            provider_dao.set provider
            # build response
            provider.endpoints = endpoint_dao.get_collection(provider.endpoints)
            present provider, with: Models::Provider
          end

          desc 'Delete a provider entity' do
            # empty response body, therefore no actual success message
            failure [[204, 'Provider deleted']].concat ErrorResponses.standard_responses
          end
          params do
            use :provider_id
          end
          delete ':provider_id' do
            provider = load_provider
            provider_dao.delete(params[:provider_id])
            # remove the provider from the vendor
            vendor = load_vendor(vendor_id: provider.vendor)
            vendor.providers.delete provider.id unless vendor.providers.nil?
            vendor_dao.set vendor
            # cascade delete operation, remove all associated endpoints
            provider.endpoints.each do |endpoint_id|
              endpoint_dao.delete endpoint_id
            end unless provider.endpoints.nil?
            # respond with 204 when entity is deleted (see rfc7231), no content
            status 204
          end
        end # provider namespace
      end
    end
  end
end
