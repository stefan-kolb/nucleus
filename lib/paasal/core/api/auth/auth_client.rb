module Paasal
  module Adapters
    class AuthClient
      attr_reader :verify_ssl

      # Create a new instance of an {AuthClient}.
      # @param [Boolean] check_certificates true if SSL certificates are to be validated,
      # false if they are to be ignored (e.g. when using self-signed certificates in development environments)
      def initialize(check_certificates = true)
        @verify_ssl = check_certificates
      end

      # Perform authentication with the given username and password at the desired endpoint.
      # @param[String] username username to use for authentication
      # @param[String] password password to the username, which is to be used for authentication
      # @raise[Paasal::Errors::AuthenticationError] if authentication failed
      # @raise[Paasal::Errors::UnknownAdapterCallError] if the generic AuthClient did expect the endpoint
      # to behave differently, usually indicates implementation issues
      # @return[Paasal::Adapters::AuthClient] current AuthClient instance
      def authenticate(username, password)
        fail Errors::AuthenticationError, 'Authentication client does not support authentication'
      end

      # Get the authentication header for the current AuthClient instance that must be used to execute requests
      # against the endpoint.<br>
      # If the authentication is known to be expired, a refresh will be made first.
      # @raise[Paasal::Errors::AuthenticationError] if the refresh failed
      # @return[Hash<String, String>] authentication header that enables requests against the endpoint
      def auth_header
        fail Errors::AuthenticationError, 'Authentication client does not support to create the authentication header'
      end

      # Refresh a rejected authentication and generate a new authentication header.<br>
      # Should be called if the authentication is known to be expired, or when a request is rejected with an
      # authentication header that used to be accepted.
      # @raise [Paasal::Errors::AuthenticationError] if token refresh failed or authentication never succeeded
      # @return [Paasal::Adapters::AuthClient] current AuthClient instance
      def refresh
        fail Errors::AuthenticationError, 'Authentication client does not support refresh'
      end
    end
  end
end
