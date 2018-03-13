module Nucleus
  module Adapters
    class OAuth2AuthClient < AuthClient
      include Nucleus::Logging

      # Create a new instance of an {OAuth2AuthClient}, which uses the standardized OAuth2 authentication method.
      # @param [Boolean] check_certificates true if SSL certificates are to be validated,
      # false if they are to be ignored (e.g. when using self-signed certificates in development environments)
      # @param [String] auth_url URL to the OAuth2 endpoint
      def initialize(auth_url, check_certificates = true)
        @auth_url = auth_url
        super(check_certificates)
      end

      def authenticate(username, password)
        return self if @access_token
        response = post(query: { grant_type: 'password', username: username, password: password })
        body = body(response)
        extract(body)
        # refresh token is not included in later updates
        @refresh_token = body[:refresh_token]
        self
      end

      def auth_header
        raise Errors::EndpointAuthenticationError, 'Authentication client was not authenticated yet' unless @access_token
        if expired?
          log.debug('OAuth2 access_token is expired, trigger refresh before returning auth_header')
          # token is expired, renew first
          refresh
        end
        # then return the authorization header
        header
      end

      def refresh
        raise Errors::EndpointAuthenticationError, "Can't refresh token before initial authentication" if @refresh_token.nil?
        log.debug("Attempt to refresh the access_token with our refresh_token: '#{@refresh_token}'")
        response = post(query: { grant_type: 'refresh_token', refresh_token: @refresh_token })
        extract(body(response))
        self
      end

      private

      def post(params)
        middleware = Excon.defaults[:middlewares].dup
        middleware << Excon::Middleware::Decompress
        middleware << Excon::Middleware::RedirectFollower
        # explicitly allow redirects, otherwise they would cause an error
        # TODO: Basic Y2Y6 could be cloud-foundry specific
        request_params = { expects: [200, 301, 302, 303, 307, 308], middlewares: middleware.uniq,
                           headers: { 'Authorization' => 'Basic Y2Y6',
                                      'Content-Type' => 'application/x-www-form-urlencoded',
                                      'Accept' => 'application/json' } }.merge(params)
        # execute the post request and return the response
        Excon.new(@auth_url, ssl_verify_peer: verify_ssl).post(request_params)
      rescue Excon::Errors::HTTPStatusError => e
        log.debug "OAuth2 authentication failed: #{e}"
        case e.response.status
        when 403
          log.error("OAuth2 for '#{@auth_url}' failed with status 403 (access denied), indicating an adapter issue")
          raise Errors::UnknownAdapterCallError, 'Access to resource denied, probably the adapter must be updated'
        when 400, 401
          raise Errors::EndpointAuthenticationError, body(e.response)[:error_description]
        end
        # re-raise all unhandled exception, indicating adapter issues
        raise Errors::UnknownAdapterCallError, 'OAuth2 call failed unexpectedly, probably the adapter must be updated'
      end

      def header
        { 'Authorization' => "#{@token_type} #{@access_token}" }
      end

      def expired?
        return true if @expiration.nil?
        Time.now >= @expiration
      end

      def body(response)
        Oj.load(response.body, symbol_keys: true)
      end

      def extract(body)
        @access_token = body[:access_token]
        # number of seconds until expiration, deduct processing buffer
        seconds_left = body[:expires_in] - 30
        @expiration = Time.now + seconds_left
        @token_type = body[:token_type]
      end
    end
  end
end
