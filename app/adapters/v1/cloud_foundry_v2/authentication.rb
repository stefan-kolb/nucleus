module Paasal
  module Adapters
    module V1
      class CloudFoundryV2 < Stub
        # Authentication functionality to support the Cloud Foundry API
        module Authentication
          # @see Stub#auth_client
          def auth_client
            auth_endpoint = endpoint_info[:authorization_endpoint]
            log.debug "Authenticate @ #{auth_endpoint}/oauth/token"
            OAuth2AuthClient.new("#{auth_endpoint}/oauth/token", @check_certificates)
          end
        end
      end
    end
  end
end
