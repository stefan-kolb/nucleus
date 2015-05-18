module Paasal
  module Adapters
    class TokenAuthClient < AuthClient
      attr_reader :api_token

      # Create a new instance of an {TokenAuthClient}.
      # @param [Boolean] check_certificates true if SSL certificates are to be validated,
      # false if they are to be ignored (e.g. when using self-signed certificates in development environments)
      # @yield [verify_ssl, username, password] Auth credentials token parser block,
      # must provide the API token, usually retrieved from an HTTP call to the endpoint.
      # @yieldparam [Boolean] verify_ssl true if SSL certificates are to be validated,
      # false if they are to be ignored (e.g. when using self-signed certificates in development environments)
      # @yieldparam [String] username username to be used to retrieve the API token
      # @yieldparam [String] password password to be used to retrieve the API token
      # @yieldreturn [String] API token to be used for authenticated API requests,
      # nil if authentication failed, e.g. due to bad credentials
      def initialize(check_certificates = true, &token_parser)
        @token_parser = token_parser
        super(check_certificates)
      end

      def authenticate(username, password)
        token = @token_parser.call(verify_ssl, username, password)
        fail Errors::AuthenticationError, 'Authentication failed, credentials seem to be invalid' unless token
        # verification passed, credentials are valid
        @api_token = token
        self
      end

      def auth_header
        fail Errors::AuthenticationError, 'Authentication client was not authenticated yet' unless @api_token
        { 'Authorization' => "Bearer #{api_token}" }
      end
    end
  end
end
