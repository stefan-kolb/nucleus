module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        # cloud control specific token, which requires a specific +cc_auth_token+ value in the +Authorization+ header.
        class Token < Paasal::Adapters::ExpiringTokenAuthClient
          # @see Paasal::Adapters::ExpiringTokenAuthClient#auth_header
          def auth_header
            fail Paasal::Errors::AuthenticationError, 'Cached authentication token expired' if expired?
            { 'Authorization' => "cc_auth_token=\"#{api_token}\"" }
          end
        end
      end
    end
  end
end
