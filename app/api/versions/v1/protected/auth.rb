module Paasal
  module API
    module V1
      class Auth < Grape::API

        # defines the authentication for all subsequently mounted routes
        http_basic({ realm: 'PaaSal API Authorization @ %{endpoint_id}', realm_replace: [:endpoint_id] }) do |username, password, params|
          if username.nil? || username.empty? || password.nil? || password.empty?
            # never allow empty username and / or password
            false
          else
            begin
              # find a matching endpoint
              endpoint = load_endpoint(params)
              # resolve the required adapter
              index_entry = adapter_dao.get params[:endpoint_id]
              # save info for the current request, no need to retrieve multiple times
              RequestStore.store[:endpoint] = endpoint
              RequestStore.store[:adapter] = index_entry.adapter_clazz.new(index_entry.url)

              unless RequestStore.store[:adapter].cache?(username, password)
                # no auth header available, perform authentication first
                # throws an error if the authentication failed
                auth_headers = RequestStore.store[:adapter].authenticate(username, password)
                # cache the auth header so it does not have to be retrieved per request
                RequestStore.store[:adapter].cache(username, password, auth_headers)
              end
              # auth passed
              true
            rescue Errors::AuthenticationFailedError
              log.debug "Authentication attempt failed at #{endpoint.url} using '#{index_entry.adapter_clazz}'"
              false
            end
          end
        end

        ##################################
        ### Mount all protected routes ###
        ##################################

        # application list
        mount Paasal::API::V1::Applications
        # lifecycle operations
        mount Paasal::API::V1::Lifecycle::Start
        mount Paasal::API::V1::Lifecycle::Stop
        mount Paasal::API::V1::Lifecycle::Restart
        # data operations
        mount Paasal::API::V1::Data::Rebuild
        mount Paasal::API::V1::Data::Upload
        mount Paasal::API::V1::Data::Download

      end
    end
  end
end