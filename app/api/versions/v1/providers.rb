module Paasal
  module API
    module V1
      class Providers < Grape::API
        helpers Paasal::SharedParamsHelper

        helpers do
          # noinspection RubyArgCount
          params :provider_id do
            requires :provider_id, type: String, desc: "The provider's ID"
          end
        end

        resource :providers do
          # LIST providers
          desc 'Return a list of all providers'
          get '/' do
            provider_dao = Paasal::DB::ProviderDao.new version
            providers = provider_dao.all
            present providers, with: Models::Providers
          end

          # GET provider
          desc 'Get a selected provider entity via its ID' do
            success Paasal::API::Models::Provider
            failure ErrorResponses.standard_responses
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
            success Paasal::API::Models::Endpoints
            failure ErrorResponses.standard_responses
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
            success Paasal::API::Models::Endpoint
            failure ErrorResponses.standard_responses
          end
          params do
            use :provider_id
            use :endpoint
          end
          post ':provider_id/endpoints' do
            # load the vendor and verify it is valid
            provider = load_provider
            # If validation passed, all required fields are available and not null (unless explicitly allowed)
            endpoint = Endpoint.new declared(params)[:endpoint]
            endpoint.provider = provider.id
            # automatically assigns a unique ID, but the name does not have to be unique
            endpoint_dao.set endpoint
            # finally assign the endpoint to the provider's collection and present the created entity
            provider.endpoints << endpoint.id
            provider_dao.set provider
            present endpoint, with: Models::Endpoint
          end

          desc 'Update a provider entity' do
            success Models::Provider
            failure [[200, 'Provider updated', Models::Provider]].concat ErrorResponses.standard_responses
          end
          params do
            use :provider_id
            use :provider_patch
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

        # resource "providers/:providerName/:providerVersion" do
        #   params do
        #     requires :providerVersion, type: String, desc: "The version of the provider's API"
        #     requires :providerName, type: String, desc: "The provider that shall be used"
        #   end
        #   get do
        #     {
        #         d:'d',
        #         name: params[:providerName],
        #         version: params[:providerVersion]
        #     }
        #   end
        # end
      end
    end
  end
end
