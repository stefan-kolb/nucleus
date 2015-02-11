module Paasal
  module Adapters
    module V1
      class CloudControlToken < Paasal::Adapters::ExpiringToken
        def initialize(token, expires)
          @token = token
          @expires = expires
        end

        def auth_header
          fail Paasal::Errors::AuthenticationError, 'Cached authentication token expired' if expired?
          { 'Authorization' => "cc_auth_token=\"#{token}\"" }
        end
      end
    end
  end
end
