module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        class Token < Paasal::Adapters::ExpiringTokenAuthClient
          def auth_header
            fail Paasal::Errors::AuthenticationError, 'Cached authentication token expired' if expired?
            { 'Authorization' => "cc_auth_token=\"#{api_token}\"" }
          end
        end
      end
    end
  end
end
