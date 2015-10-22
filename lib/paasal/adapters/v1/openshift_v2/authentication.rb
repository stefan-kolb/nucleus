module Nucleus
  module Adapters
    module V1
      class OpenshiftV2 < Stub
        # Authentication functionality to support the Openshift V2 API
        module Authentication
          # @see Stub#auth_client
          def auth_client
            HttpBasicAuthClient.new @check_certificates do |verify_ssl, headers|
              # auth verification block
              headers['Accept'] = 'application/json; version=1.7'
              result = Excon.new("#{@endpoint_url}/user", ssl_verify_peer: verify_ssl).get(headers: headers)
              # Openshift returns 401 for invalid credentials --> auth failed, return false
              result.status != 401
            end
          end
        end
      end
    end
  end
end
