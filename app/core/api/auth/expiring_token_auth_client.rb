module Paasal
  module Adapters
    class ExpiringTokenAuthClient < TokenAuthClient
      # Create a new instance of an {ExpiringTokenAuthClient}. An expiring token knows when it starts to be invalid,
      # saving requests to the endpoint that would fail anyways.
      # @param [Boolean] check_certificates true if SSL certificates are to be validated,
      # false if they are to be ignored (e.g. when using self-signed certificates in development environments)
      # @yield [verify_ssl, username, password] Auth credentials token parser block,
      # must provide the API token and its expiration date, usually retrieved from an HTTP call to the endpoint.
      # @yieldparam [Boolean] verify_ssl true if SSL certificates are to be validated,
      # false if they are to be ignored (e.g. when using self-signed certificates in development environments)
      # @yieldparam [String] username username to be used to retrieve the API token
      # @yieldparam [String] password password to be used to retrieve the API token
      # @yieldreturn [Array<String>] Array with 2 contents:
      # [0] = API token to be used for authenticated API requests,
      # nil if authentication failed, e.g. due to bad credentials
      # [1] = Expiration time until the token is valid
      def initialize(check_certificates = true, &token_expiration_parser)
        @token_expiration_parser = token_expiration_parser
        super(check_certificates)
      end

      def authenticate(username, password)
        token, expiration_time = @token_expiration_parser.call(verify_ssl, username, password)
        fail Errors::AuthenticationError, 'Authentication failed, credentials seem to be invalid' unless token
        # verification passed, credentials are valid
        @api_token = token
        @expires = expiration_time
        self
      end

      def auth_header
        fail Paasal::Errors::AuthenticationError, 'Cached authentication token expired' if expired?
        fail Errors::AuthenticationError, 'Authentication client was not authenticated yet' unless @api_token
        { 'Authorization' => "Bearer #{api_token}" }
      end

      private

      # Checks if the token is expired.
      # @return [true, false] true if the token is expired, false if it is still valid
      def expired?
        @expires >= Time.now
      end

      def to_s
        api_token
      end
    end
  end
end
