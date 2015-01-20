module Paasal
  module API
    module V1
      class Endpoints < Grape::API

        helpers do
          # noinspection RubyArgCount
          params :endpoint_id do
            requires :endpoint_id, type: String, desc: "The endpoint's ID in the form of a UUID."
          end
        end

        resource :endpoints do

          # # LIST endpoints
          # desc 'List of available endpoints'
          # get '/' do
          #   endpoint_dao = Paasal::DB::EndpointDao.new self.version
          #   endpoints = endpoint_dao.get_all
          #   present endpoints, with: Models::Endpoints
          # end

          # GET endpoint
          desc 'Get a selected endpoint entity via its ID'
          params do
            use :endpoint_id
          end
          get ':endpoint_id' do
            endpoint_dao = Paasal::DB::EndpointDao.new self.version
            endpoint = endpoint_dao.get params[:endpoint_id]
            to_error(ErrorMessages::NOT_FOUND, "No endpoint found with the ID '#{params[:endpoint_id]}'") if endpoint.nil?
            present endpoint, with: Models::Endpoint
          end

          # GET all applications behind an endpoint
          desc 'Get all applications that are registered at the endpoint' do
            success Paasal::API::Models::Applications
            failure ErrorResponses.standard_responses
          end
          params do
            use :endpoint_id
          end
          # TODO extract to use only once for all protected resources
          http_basic({ realm: 'PaaSal API Authorization @ %{endpoint_id}', realm_replace: [:endpoint_id] }) do |username, password, params|
            begin
              # find a matching endpoint
              endpoint_dao = Paasal::DB::EndpointDao.new params[:version]
              endpoint = endpoint_dao.get params[:endpoint_id]
              to_error(ErrorMessages::NOT_FOUND, "No endpoint found with the ID '#{params[:endpoint_id]}'") if endpoint.nil?
              # resolve the required adapter
              adapter_dao = Paasal::DB::AdapterDao.new params[:version]
              index_entry = adapter_dao.get params[:endpoint_id]
              # save info for the current request, no need to retrieve multiple times
              RequestStore.store[:endpoint] = endpoint
              RequestStore.store[:adapter] = index_entry.adapter_clazz.new(index_entry.url)

              unless RequestStore.store[:adapter].cache?(username, password)
                # no auth header available, perform authentication first
                # throws an error if the authentication failed
                RequestStore.store[:auth_header] = RequestStore.store[:adapter].authenticate(username, password)
                # cache the auth header so it does not have to be retrieved per request
                RequestStore.store[:adapter].cache(username, password, RequestStore.store[:auth_header])
              end
              # auth passed
              true
            rescue Errors::AuthenticationFailedError => e
              log.debug "Authentication attempt failed at #{endpoint.url} using '#{index_entry.adapter_clazz}'"
              false
            end
          end
          get ':endpoint_id/applications' do
            endpoint_dao = Paasal::DB::EndpointDao.new self.version
            endpoint = endpoint_dao.get params[:endpoint_id]
            to_error(ErrorMessages::NOT_FOUND, "No endpoint found with the ID '#{params[:endpoint_id]}'") if endpoint.nil?

            applications = repeat_on_invalid_authentication_cache do
              adapter.applications
            end

            present applications, with: Models::Applications
          end

          # LIST endpoints
          desc 'List of available endpoints'
          get '/' do
            endpoint_dao = Paasal::DB::EndpointDao.new self.version
            endpoints = endpoint_dao.get_all
            present endpoints, with: Models::Endpoints
          end

        end # provider namespace

          # TODO list all applications of this endpoint

      end
    end
  end
end