module Paasal
  module API
    module V1
      class Vendors < Grape::API

        helpers do
          # noinspection RubyArgCount
          params :vendor_id do
            requires :vendor_id, type: String, desc: "The vendor's ID in the form of a UUID."
          end
        end

        resource :vendors do

          # LIST vendors
          desc 'List of supported vendors in this API version' do
            success Paasal::API::Models::Vendors
            failure ErrorResponses.standard_responses
          end
          get '/' do
            #vendor_dao = Paasal::DB::VendorDao.new self.version
            vendors = vendor_dao.get_all
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
            #vendor_dao = Paasal::DB::VendorDao.new self.version
            vendor = vendor_dao.get params[:vendor_id]
            to_error(ErrorMessages::NOT_FOUND, "No vendor found with the ID '#{params[:vendor_id]}'") if vendor.nil?
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
            vendor = vendor_dao.get params[:vendor_id]
            to_error(ErrorMessages::NOT_FOUND, "No vendor found with the ID '#{params[:vendor_id]}'") if vendor.nil?
            providers = provider_dao.get_collection(vendor.providers)
            present providers, with: Models::Providers
          end

        end

      end
    end
  end
end