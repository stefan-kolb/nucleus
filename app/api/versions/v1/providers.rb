module Paasal
  module API
    module V1
      class Providers < Grape::API

        helpers do
          # noinspection RubyArgCount
          params :provider_id do
            requires :provider_id, type: String, desc: "The provider's ID in the form of a UUID."
          end

          def load_provider
            unless provider_dao.key? params[:provider_id]
              to_error(ErrorMessages::NOT_FOUND, "No provider found with the ID '#{params[:provider_id]}'")
            end
            provider_dao.get params[:provider_id]
          end

        end

        resource :providers do

          # # LIST providers
          # desc 'Return list of providers'
          # get '/' do
          #   provider_dao = Paasal::DB::ProviderDao.new self.version
          #   providers = provider_dao.get_all
          #   present providers, with: Models::Providers
          # end

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