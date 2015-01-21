module Paasal
  module AdapterHelper
    extend Grape::API::Helpers

    def adapter
      RequestStore.store[:adapter]
    end

    def repeat_adapter_call_on_invalid_authentication_cache
      begin
        log.debug 'Prepare repeated action call block...'
        response = yield
        log.debug '... the block did pass just fine!'
      rescue Errors::InvalidAuthenticationHeaderError
        log.debug 'Call failed, start repetition by removing outdated cache entry'
        RequestStore.store[:adapter].uncache RequestStore.store[:cache_key]

        reauthenticate

        log.debug 'Repeating call block...'
        response = yield
        log.debug '... the repetition did pass just fine!'
      end
      response
    end

    def reauthenticate
      # resolve username & password for authentication request
      auth_keys = %w(HTTP_AUTHORIZATION X-HTTP_AUTHORIZATION X_HTTP_AUTHORIZATION)
      authorization_key = auth_keys.detect { |k| @env.has_key?(k) }
      username_password = @env[authorization_key].split(' ', 2).last
      credentials = username_password.unpack('m*').first.split(/:/, 2)
      # raises 401 if the authentication did not only expire, but became completely invalid
      auth_headers = RequestStore.store[:adapter].authenticate(credentials[0], credentials[1])
      RequestStore.store[:adapter].cache(credentials[0], credentials[1], auth_headers)
    end

  end
end
