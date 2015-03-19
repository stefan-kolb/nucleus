module Paasal
  module AdapterHelper
    extend Grape::API::Helpers
    include Paasal::Logging

    # Get the adapter that is assigned to the current request (via endpoint)
    # @return [Paasal::Adapters::BaseAdapter] adapter for the currently used endpoint and its vendor
    def adapter
      RequestStore.store[:adapter]
    end

    # Executes a block, which should be an adapter call, using the authentication information.
    # If the first call fails due to cached authentication information, the cache is going to get evicted,
    # authentication repeated and finally the call will be executed again.
    # Also supports OAuth2 authentication.
    #
    # @return [Hash, void] result of the yield block execution, usually a Hash matching the Grape::Entity to represent
    def with_authentication
      begin
        response = yield
      rescue Errors::OAuth2AuthenticationError => e
        refresh_token e.o2auth_client
        response = yield
      rescue Errors::AuthenticationError
        log.debug 'Call failed, start repetition by removing outdated cache entry'
        re_authenticate
        log.debug 'Repeating call block...'
        response = yield
        log.debug '... the repetition did pass just fine!'
      end
      response
    end

    # Refresh OAuth2 the access token.
    # The method shall only be invoked when there are cached authentication information that appear to be outdated and
    # OAuth2 authentication is used for the current adapter.
    # If the refresh fails, a re-authentication will be forced.
    #
    # @raise [Paasal::Errors::AuthenticationError] if refresh and authentication at the endpoint both fail
    # @return [void]
    def refresh_token(o2auth_client)
      # With OAuth2 we first try to renew our token before invalidating the cache
      log.debug 'Call failed with OAuth2, start refreshing auth token'
      o2auth_client.refresh unless o2auth_client.nil?
      log.debug '... the OAuth2 token refresh succeeded'
    rescue Errors::OAuth2AuthenticationError
      # If authentication fails again, invalidate the refresh_token and start clean again
      log.debug 'Call failed repeatedly with OAuth2, force re-authentication'
      re_authenticate
      log.debug '... the OAuth2 re-authentication succeeded'
    end

    # Re-authenticate the user with the help of the current adapter.
    # The method shall only be invoked when there are cached authentication information that appear to be outdated.
    # It invalidates the cache for the current user and calls the authentication.
    #
    # @raise [Paasal::Errors::AuthenticationError] if authentication at the endpoint fails
    # @return [void]
    def re_authenticate
      log.debug('Invokded re-authentication')
      RequestStore.store[:adapter].uncache RequestStore.store[:cache_key]
      # resolve username & password for authentication request
      auth_keys = %w(HTTP_AUTHORIZATION X-HTTP_AUTHORIZATION X_HTTP_AUTHORIZATION)
      authorization_key = auth_keys.detect { |k| @env.key?(k) }
      username, password = @env[authorization_key].split(' ', 2).last.unpack('m*').first.split(/:/, 2)
      # raises 401 if the authentication did not only expire, but became completely invalid
      adapter = RequestStore.store[:adapter]
      adapter.cache(username, password, adapter.authenticate(username, password))
    end
  end
end
