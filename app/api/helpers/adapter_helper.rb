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
      rescue Errors::InvalidAuthenticationHeaderError => e
        log.debug 'Call failed, start repetition by removing outdated cache entry'
        RequestStore.store[:adapter].uncache RequestStore.store[:cache_key]

        # resolve username & password for authentication request
        authorization_key = ['HTTP_AUTHORIZATION', 'X-HTTP_AUTHORIZATION', 'X_HTTP_AUTHORIZATION'].detect { |k| @env.has_key?(k) }
        username_password = @env[authorization_key].split(' ', 2).last
        credentials = username_password.unpack('m*').first.split(/:/, 2)
        # raises 401 if the authentication did not only expire, but became completely invalid
        RequestStore.store[:auth_header] = RequestStore.store[:adapter].authenticate(credentials[0], credentials[1])

        log.debug 'Repeating call block...'
        response = yield
        log.debug '... the repetition did pass just fine!'
      end
      response
    end

  end
end