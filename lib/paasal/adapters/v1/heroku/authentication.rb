module Nucleus
  module Adapters
    module V1
      class Heroku < Stub
        # Authentication functionality to support the Heroku API
        module Authentication
          # @see Stub#auth_client
          def auth_client
            log.debug "Authenticate @ #{@endpoint_url}"
            TokenAuthClient.new @check_certificates do |verify_ssl, username, password|
              response = Excon.post("#{@endpoint_url}/login", query: { username: username, password: password },
                                   ssl_verify_peer: verify_ssl)
              # Heroku returns 404 for invalid credentials, then we do not return an API token
              if response.status == 404
                nil
              else
                # extract the token
                response_parsed = JSON.parse(response.body)
                response_parsed['api_key']
              end
            end
          end
        end
      end
    end
  end
end
