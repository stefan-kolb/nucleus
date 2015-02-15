# noinspection ALL
module Paasal
  module SharedParamsHelper
    extend Grape::API::Helpers

    params :endpoint_id do
      requires :endpoint_id, type: String, desc: "The endpoint's ID"
    end

    params :application_context do
      use :endpoint_id
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

    params :create_application do
      # require the keys of the application in the json object 'application'
      requires :application, type: Hash do
        # name is required, but we must use :all to get the presence validator. Name is selected via :using
        requires :all, using: Paasal::API::Models::Application.documentation.slice(:name)
        # everything else is optional
        optional :all, using: Paasal::API::Models::Application.documentation
          .except(:id, :name, :state, :created_at, :updated_at, :_links)
      end
    end

    params :update_application do
      # require the keys of the application in the json object 'application'
      requires :application, type: Hash do
        optional :all, using: Paasal::API::Models::Application.documentation
          .except(:id, :state, :created_at, :updated_at, :_links)
      end
    end
  end
end
