module Nucleus
  module Adapters
    # The AuthenticationRetryWrapper module can be used to invoke commands in a block that repeats its execution in case
    # the first attempt raises an {Nucleus::Errors::EndpointAuthenticationError}.
    module AuthenticationRetryWrapper
      extend Nucleus::Logging

      # Executes a block, which should be an adapter call, using the authentication information.
      # If the first call fails due to cached authentication information, the cache is going to get evicted,
      # authentication repeated and finally the call will be executed again.
      #
      # @param [Nucleus::Adapters::BaseAdapter] adapter adapter that is used for the ongoing request
      # @param [Hash<String, String>] env Rack environment, shall contain HTTP authentication information
      # @return [Hash, void] result of the yield block execution, usually a Hash matching the Grape::Entity to represent
      def self.with_authentication(adapter, env)
        begin
          response = yield
        rescue Errors::EndpointAuthenticationError
          # first attempt with actually valid credentials failed, try to refresh token based clients
          username, password = username_password(env)
          begin
            auth_client = adapter.cached(adapter.cache_key(username, password))
            auth_client.refresh
            response = yield
          rescue Errors::EndpointAuthenticationError
            # refresh failed, too
            log.debug 'Call failed (401), start repetition by removing outdated cache entry'
            re_authenticate(adapter, env)
            log.debug 'Repeating call block...'
            response = yield
            log.debug '... the repetition did pass just fine!'
          end
        end
        response
      end

      # Try to refresh a token based authentication that can be renewed.
      # The method shall only be invoked when there are cached authentication information
      # that appear to be outdated.<br>
      # If the refresh fails, a complete re-authentication will be forced.
      #
      # @param [Nucleus::Adapters::AuthClient] auth_client platform specific version of the authentication client
      # @raise [Nucleus::Errors::EndpointAuthenticationError] if both, refresh and authentication fail
      # @return [void]
      def self.refresh_token(auth_client)
        # we first try to renew our token before invalidating the cache
        log.debug 'Call failed (401), start refreshing auth token'
        auth_client.refresh unless auth_client.nil?
        log.debug '... the auth token refresh succeeded'
      end

      # Re-authenticate the user with the help of the current adapter.
      # The method shall only be invoked when there are cached authentication information that appear to be outdated.
      # It calls the authentication for the current user to override the cached authentication headers.
      #
      # @param [Nucleus::Adapters::BaseAdapter] adapter adapter that is used for the ongoing request
      # @param [Hash<String, String>] env Rack environment, shall contain HTTP authentication information
      # @raise [Nucleus::Errors::EndpointAuthenticationError] if authentication at the endpoint fails
      # @return [void]
      def self.re_authenticate(adapter, env)
        log.debug('Invoked re-authentication')
        username, password = username_password(env)
        auth_client = adapter.cached(adapter.cache_key(username, password))
        # raises 401 if the authentication did not only expire, but became completely invalid
        auth_client.authenticate(username, password)
      end

      # Extract the username and password from the current HTTP request.
      # @param [Hash<String, String>] env Rack environment, shall contain HTTP authentication information
      # @return [Array<String>] username at response[0], password at response[1]
      def self.username_password(env)
        # resolve username & password for authentication request
        auth_keys = %w[HTTP_AUTHORIZATION X-HTTP_AUTHORIZATION X_HTTP_AUTHORIZATION]
        authorization_key = auth_keys.detect { |k| env.key?(k) }
        env[authorization_key].split(' ', 2).last.unpack('m*').first.split(/:/, 2)
      end
    end
  end
end
