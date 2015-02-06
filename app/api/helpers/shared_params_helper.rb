module Paasal
  module SharedParamsHelper
    extend Grape::API::Helpers

    params :endpoint_id do
      requires :endpoint_id, type: String, desc: "The endpoint's ID"
    end

    params :application_id do
      requires :application_id, type: String, desc: "The application's ID"
    end

    params :create_provider do
      # require the keys of the provider in the json object 'provider'
      requires :provider, type: Hash do
        requires :all, using: Paasal::API::Models::Provider.documentation.except(
          :id, :endpoints, :created_at, :updated_at, :key, :_links)
      end
    end

    params :update_provider do
      requires :provider, type: Hash do
        optional :all, using: Paasal::API::Models::Provider.documentation
          .except(:id, :endpoints, :vendor, :created_at, :updated_at, :key, :_links)
      end
    end

    params :create_endpoint do
      # require the keys of the endpoint in the json object 'endpoint'
      requires :endpoint, type: Hash do
        requires :all, using: Paasal::API::Models::Endpoint.documentation.except(
          :id, :applications, :created_at, :updated_at, :key, :_links)
      end
    end

    params :update_endpoint do
      requires :endpoint, type: Hash do
        optional :all, using: Paasal::API::Models::Endpoint.documentation
          .except(:id, :applications, :created_at, :updated_at, :key, :_links)
      end
    end
  end
end
