module Paasal
  module Adapters
    class HttpBasicAuthClient < AuthClient
      # Create a new instance of an {HttpBasicAuthClient}.
      # @param [Boolean] check_certificates true if SSL certificates are to be validated,
      # false if they are to be ignored (e.g. when using self-signed certificates in development environments)
      # @yield [verify_ssl, username, password] Auth credentials verification block,
      # must check if the combination of username and password is accepted by the endpoint.
      # @yieldparam [Hash<String,String>] headers headers for an HTTP request,
      # including the authentication header to be tested
      # @yieldreturn [Boolean] true if the authentication was verified to be ok,
      # false if an error occurred, e.g. with bad credentials
      def initialize(check_certificates = true, &verification)
        @verification = verification
        super(check_certificates)
      end

      def authenticate(username, password)
        packed_credentials = ["#{username}:#{password}"].pack('m*').gsub(/\n/, '')
        valid = @verification.call(verify_ssl, 'Authorization' => "Basic #{packed_credentials}")
        fail Errors::AuthenticationError, 'Authentication failed, credentials seem to be invalid' unless valid
        # verification passed, credentials are valid
        @packed_credentials = packed_credentials
        self
      end

      def auth_header
        fail Errors::AuthenticationError, 'Authentication client was not authenticated yet' unless @packed_credentials
        { 'Authorization' => "Basic #{@packed_credentials}" }
      end
    end
  end
end
