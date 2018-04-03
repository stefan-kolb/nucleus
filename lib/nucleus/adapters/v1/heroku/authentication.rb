require 'base64'

module Nucleus
  module Adapters
    module V1
      class Heroku < Stub
        # Authentication functionality to support the Heroku API
        # @see{https://devcenter.heroku.com/articles/oauth#direct-authorization}
        module Authentication
          # @see Stub#auth_client
          def auth_client
            log.debug "Authenticate @ #{@endpoint_url}"

            TokenAuthClient.new @check_certificates do |verify_ssl, username, password|
              packed_credentials = Base64.strict_encode64("#{username}:#{password}")
              headers = {'Accept' => 'application/vnd.heroku+json; version=3',
                         'Content-Type' => 'application/json', 'Authorization' => "Basic #{packed_credentials}"}
              response = Excon.new("#{@endpoint_url}/oauth/authorizations", ssl_verify_peer: verify_ssl).post(headers: headers)
              # Heroku returns 401 for invalid credentials, then we do not return an API token
              if response.status == 401
                nil
              else
                # extract the token
                response_parsed = JSON.parse(response.body)
                response_parsed['access_token']['token']
              end
            end
          end
        end
      end
    end
  end
end
