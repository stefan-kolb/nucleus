module Nucleus
  module API
    module V1
      class Auth < Grape::API
        helpers SharedParamsHelper

        # defines the authentication for all subsequently mounted routes
        http_basic(realm: 'Nucleus API Authorization @ %{endpoint_id}',
                   realm_replace: [:endpoint_id]) do |username, password, params, env|
          if username.nil? || username.empty? || password.nil? || password.empty?
            # never allow empty username and / or password
            false
          else
            # find a matching endpoint
            endpoint = load_endpoint(params)
            # resolve the required adapter
            index_entry = adapter_dao.get params[:endpoint_id]
            # use the already secured (https) URL of the index_entry
            adapter = index_entry.adapter_clazz.new(index_entry.url, endpoint.app_domain, !endpoint.trust)

            # patch the adapter so that calls are wrapped and expect valid authentication
            AdapterAuthenticationInductor.patch(adapter, env)

            # save info for the current request, no need to retrieve multiple times
            request_cache.set("#{env['HTTP_X_REQUEST_ID']}.adapter", adapter)
            request_cache.set("#{env['HTTP_X_REQUEST_ID']}.endpoint", endpoint)

            cache_key = adapter.cache_key(username, password)
            # THREAD HACK to work with deferred tasks (log tailing), cache auth key
            request_cache.set("#{env['HTTP_X_REQUEST_ID']}.auth.cache.key", cache_key)

            unless adapter.cache?(cache_key)
              # no auth object available, perform authentication first
              auth_object = adapter.auth_client
              # throws an error if the authentication failed
              auth_object.authenticate(username, password)
              # cache the auth object so it does not have to be retrieved per request
              adapter.cache(cache_key, auth_object)
            end
            # auth passed
            true
          end
        end

        ##################################
        ### Mount all protected routes ###
        ##################################

        # enable native endpoint calls, no param checks, no uniform responses (!)
        mount Nucleus::API::V1::Calls

        # regions list
        mount Nucleus::API::V1::Regions

        # application operations
        mount Nucleus::API::V1::Applications
        # application - data operations
        mount Nucleus::API::V1::ApplicationData
        # application - domain operations
        mount Nucleus::API::V1::ApplicationDomains
        # application - environment variables
        mount Nucleus::API::V1::ApplicationEnvVars
        # application - lifecycle operations
        mount Nucleus::API::V1::ApplicationLifecycle
        # application - logging operations
        mount Nucleus::API::V1::ApplicationLogs
        mount Nucleus::API::V1::ApplicationLogsTail
        # application - scaling operations
        mount Nucleus::API::V1::ApplicationScaling
        # application - services
        mount Nucleus::API::V1::ApplicationServices

        # service operations
        mount Nucleus::API::V1::Services
        # service plan operations
        mount Nucleus::API::V1::ServicePlans
      end
    end
  end
end
