module Paasal
  module API
    module V1
      class Vendors < Grape::API
        helpers SharedParamsHelper

        helpers do
          # noinspection RubyArgCount
          params :vendor_id do
            requires :vendor_id, type: String, desc: "The vendor's ID"
          end
        end

        resource :vendors do
          # LIST vendors
          desc 'List of supported vendors in this API version' do
            success Models::Vendors
            failure [[200, 'Vendors retrieved', Models::Vendors]].concat ErrorResponses.standard_responses
          end
          get '/' do
            vendors = vendor_dao.all || []
            present vendors, with: Models::Vendors
          end

          # GET vendor
          desc 'Get a selected vendor entity via its ID' do
            success Models::Vendor
            failure [[200, 'Vendor retrieved', Models::Vendor]].concat ErrorResponses.standard_responses
          end
          params do
            use :vendor_id
          end
          get ':vendor_id' do
            vendor = load_vendor
            vendor.providers = provider_dao.get_collection(vendor.providers)
            present vendor, with: Models::Vendor
          end

          # GET a vendor's providers
          desc 'Get all providers that use this vendor' do
            success Models::Providers
            failure [[200, 'Providers retrieved', Models::Providers]].concat ErrorResponses.standard_responses
          end
          params do
            use :vendor_id
          end
          get ':vendor_id/providers' do
            vendor = load_vendor
            providers = provider_dao.get_collection(vendor.providers)
            present providers, with: Models::Providers
          end

          desc 'Create a new provider entity that belongs to this vendor' do
            success Models::Provider
            failure [[201, 'Provider created', Models::Provider]].concat ErrorResponses.standard_responses
          end
          params do
            use :vendor_id
            requires :provider, type: Hash do
              requires :all, using: Paasal::API::Models::Provider.documentation
                .except(:id, :endpoints, :created_at, :updated_at, :_links)
            end
          end
          post ':vendor_id/providers' do
            # load the vendor and verify it is valid
            vendor = load_vendor
            # If validation passed, all required fields are available and not null (unless explicitly allowed).
            # Fields that were not allowed (id, ...) are excluded via declared(params)
            provider = Provider.new declared(params)[:provider]
            provider.vendor = vendor.id
            # automatically assigns a unique ID, but the name does not have to be unique
            provider_dao.set provider
            # finally assign the provider to the vendor's collection and present the created entity
            vendor.providers << provider.id
            vendor_dao.set vendor
            # add location header that refers to the created entity (see RFC7231 p.68)
            header 'Location', link_generator.resource(%w(providers), provider.id)
            present provider, with: Models::Provider
          end
        end # vendor namespace
      end
    end
  end
end
