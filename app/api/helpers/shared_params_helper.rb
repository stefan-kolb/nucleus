module Paasal
  module SharedParamsHelper
    extend Grape::API::Helpers

    params :endpoint_id do
      requires :endpoint_id, type: String, desc: "The endpoint's ID"
    end

    params :vendor do
      # require the keys of the vendor in the json object 'vendor'
      requires :vendor, type: Hash do
        requires :all, using: Paasal::API::Models::Vendor.documentation.except(
                         :id, :providers, :created_at, :updated_at, :key, :_links)
      end
    end

    params :provider do
      # require the keys of the provider in the json object 'provider'
      requires :provider, type: Hash do
        requires :all, using: Paasal::API::Models::Provider.documentation.except(
                         :id, :endpoints, :created_at, :updated_at, :key, :_links)
      end
    end

    params :endpoint do
      # require the keys of the endpoint in the json object 'endpoint'
      requires :endpoint, type: Hash do
        requires :all, using: Paasal::API::Models::Endpoint.documentation.except(
                         :id, :applications, :created_at, :updated_at, :key, :_links)
      end
    end
  end
  # require the keys of the vendor in the post body root
  # requires :all, using: Paasal::API::Models::Vendor.documentation.except(:providers, :_links)
end
