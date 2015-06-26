module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        # Authentication functionality to support the cloudControl API
        module Authentication
          # @see Stub#auth_client
          def auth_client
            Token.new @check_certificates do |_verify_ssl, username, password|
              auth_headers = { 'Authorization' => 'Basic ' + ["#{username}:#{password}"].pack('m*').gsub(/\n/, '') }
              begin
                # ssl verification is implemented by the HttpClient itself
                response = post('/token', headers: auth_headers)
                # parse to retrieve the token and expiration date
                expires = Time.parse(response.body[:expires])
                [response.body[:token], expires]
              rescue Errors::ApiError
                # ignore the error, return nil for failed authentication
                nil
              end
            end
          end
        end
      end
    end
  end
end
