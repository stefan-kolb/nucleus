module Paasal
  module API
    module V1
      class Auth < Grape::API
        helpers Paasal::SharedParamsHelper

        # defines the authentication for all subsequently mounted routes
        http_basic(realm: 'PaaSal API Authorization @ %{endpoint_id}',
                   realm_replace: [:endpoint_id]) do |username, password, params|
          if username.nil? || username.empty? || password.nil? || password.empty?
            # never allow empty username and / or password
            false
          else
            # find a matching endpoint
            endpoint = load_endpoint(params)
            # resolve the required adapter
            index_entry = adapter_dao.get params[:endpoint_id]
            # save info for the current request, no need to retrieve multiple times
            RequestStore.store[:endpoint] = endpoint
            RequestStore.store[:adapter] = index_entry.adapter_clazz.new(index_entry.url, !endpoint.trust)

            unless RequestStore.store[:adapter].cache?(username, password)
              # no auth object available, perform authentication first
              # throws an error if the authentication failed
              auth_object = RequestStore.store[:adapter].authenticate(username, password)
              # cache the auth object so it does not have to be retrieved per request
              RequestStore.store[:adapter].cache(username, password, auth_object)
            end
            # auth passed
            true
          end
        end

        ##################################
        ### Mount all protected routes ###
        ##################################

        # application list
        mount Paasal::API::V1::Applications
        # regions list
        mount Paasal::API::V1::Regions

        # # lifecycle operations
        # mount Paasal::API::V1::Lifecycle::Start
        # mount Paasal::API::V1::Lifecycle::Stop
        # mount Paasal::API::V1::Lifecycle::Restart
        # # data operations
        # mount Paasal::API::V1::Data::Rebuild
        # mount Paasal::API::V1::Data::Upload
        # mount Paasal::API::V1::Data::Download
        # domain operations
        # mount Paasal::API::V1::Domains::Get
        mount Paasal::API::V1::Domains::List
        # mount Paasal::API::V1::Domains::Create
        # mount Paasal::API::V1::Domains::Update
        # mount Paasal::API::V1::Domains::Delete
      end
    end
  end
end
