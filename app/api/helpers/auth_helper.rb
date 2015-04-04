module Paasal
  module AuthHelper
    extend Grape::API::Helpers
    include Paasal::Logging

    # Executes a block, which should be an adapter call, using the authentication information.
    # If the first call fails due to cached authentication information, the cache is going to get evicted,
    # authentication repeated and finally the call will be executed again.
    #
    # @return [Hash, void] result of the yield block execution, usually a Hash matching the Grape::Entity to represent
    def with_authentication
      begin
        response = yield
      rescue Errors::AuthenticationError
        # first attempt with actually valid credentials failed, try to refresh token based clients
        username, password = username_password
        begin
          auth_client = adapter.cached(adapter.cache_key(username, password))
          auth_client.refresh
          response = yield
        rescue Errors::AuthenticationError
          # refresh failed, too
          log.debug 'Call failed (401), start repetition by removing outdated cache entry'
          re_authenticate
          log.debug 'Repeating call block...'
          response = yield
          log.debug '... the repetition did pass just fine!'
        end
      end
      response
    end

    # Try to refresh a token based authentication that can be renewed.
    # The method shall only be invoked when there are cached authentication information that appear to be outdated.<br>
    # If the refresh fails, a complete re-authentication will be forced.
    #
    # @raise [Paasal::Errors::AuthenticationError] if both, refresh and authentication fail
    # @return [void]
    def refresh_token(auth_client)
      # we first try to renew our token before invalidating the cache
      log.debug 'Call failed (401), start refreshing auth token'
      auth_client.refresh unless auth_client.nil?
      log.debug '... the auth token refresh succeeded'
    end

    # Re-authenticate the user with the help of the current adapter.
    # The method shall only be invoked when there are cached authentication information that appear to be outdated.
    # It invalidates the cache for the current user and calls the authentication.
    #
    # @raise [Paasal::Errors::AuthenticationError] if authentication at the endpoint fails
    # @return [void]
    def re_authenticate
      log.debug('Invokded re-authentication')
      adapter.uncache(request_cache.get("#{@env['HTTP_X_REQUEST_ID']}.cache_key"))
      username, password = username_password
      cache_key = adapter.cache_key(username, password)
      # raises 401 if the authentication did not only expire, but became completely invalid
      adapter.cache(cache_key, adapter.authenticate(username, password))
    end

    # Extract the username and password from the current HTTP request.
    # @return [Array<String>] username at response[0], password at response[1]
    def username_password
      # resolve username & password for authentication request
      auth_keys = %w(HTTP_AUTHORIZATION X-HTTP_AUTHORIZATION X_HTTP_AUTHORIZATION)
      authorization_key = auth_keys.detect { |k| @env.key?(k) }
      @env[authorization_key].split(' ', 2).last.unpack('m*').first.split(/:/, 2)
    end
  end
end
