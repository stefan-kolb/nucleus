module Paasal
  module API
    module V1
      class Auth < Grape::API

        # defines the authentication for all subsequently mounted routes
        http_basic({ realm: 'PaaSal API Authorization @ %{endpoint_id}', realm_replace: [:endpoint_id] }) do |username, password, params|
          if username.nil? || username.empty? || password.nil? || password.empty?
            # never allow empty usernames and / or passwords
            false
          else
            begin
              # find a matching endpoint
              endpoint = load_endpoint(params)
              # resolve the required adapter
              #adapter_dao = Paasal::DB::AdapterDao.new params[:version]
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
        end

        # mount all protected routes
        mount Paasal::API::V1::Applications

      end
    end
  end
end