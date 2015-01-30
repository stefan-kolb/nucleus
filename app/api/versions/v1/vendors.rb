module Paasal
  module API
    module V1
      class Vendors < Grape::API
        helpers Paasal::SharedParamsHelper

        helpers do
          # noinspection RubyArgCount
          params :vendor_id do
            requires :vendor_id, type: String, desc: "The vendor's ID"
          end
        end

        resource :vendors do
          # LIST vendors
          desc 'List of supported vendors in this API version' do
            success Paasal::API::Models::Vendors
            failure ErrorResponses.standard_responses
          end
          get '/' do
            vendors = vendor_dao.all
            present vendors, with: Models::Vendors
          end

          # GET vendor
          desc 'Get a selected vendor entity via its ID' do
            success Paasal::API::Models::Vendor
            failure ErrorResponses.standard_responses
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
            success Paasal::API::Models::Providers
            failure ErrorResponses.standard_responses
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
            success Paasal::API::Models::Provider
            failure ErrorResponses.standard_responses
          end
          params do
            use :vendor_id
            use :provider
          end
          post ':vendor_id/providers' do
            # load the vendor and verify it is valid
            vendor = load_vendor
            # If validation passed, all required fields are available and not null (unless explicitly allowed)
            provider = Provider.new declared(params)[:provider]
            provider.vendor = vendor.id
            # automatically assigns a unique ID, but the name does not have to be unique
            provider_dao.set provider
            # finally assign the provider to the vendor's collection and present the created entity
            vendor.providers << provider.id
            vendor_dao.set vendor
            present provider, with: Models::Provider
          end
        end # vendor namespace
      end
    end
  end
end
