module Paasal
  class OAuth2Client
    include Paasal::Logging

    def initialize(auth_url, check_certificates = true)
      @auth_url = auth_url
      @check_certificates = check_certificates
    end

    # Authenticate with the given username and password at the auth url.
    # @param[String] username username
    # @param[String] password password to the username
    # @raise[Paasal::Errors::OAuth2AuthenticationError] if authentication failed due to the username and / or password
    # @raise[Paasal::Errors::UnknownAdapterCallError] if the OAuth2Client does not match the endpoint's auth method
    # @return[Paasal::O2AuthClient] current OAuth2Client instance
    def authenticate(username, password)
      return self if @access_token
      response = post(query: { grant_type: 'password', username: username, password: password })
      # TODO: handle certificate errors -> temporary error !?
      body = body(response)
      extract(body)
      # refresh token is not included in later updates
      @refresh_token = body[:refresh_token]
      self
    end

    # Get the authentication header for the current OAuth2Client instance.
    # If the authentication is expired, a token refresh will be made.
    # @raise[Paasal::Errors::OAuth2AuthenticationError] if token refresh failed
    # @return[Hash<String, String>] authentication header that enables requests against the endpoint
    def auth_header
      if expired?
        log.debug('OAuth2 access_token is expired, trigger refresh before returning auth_header')
        # token is expired, renew first
        refresh
      end
      # then return the authorization header
      header
    end

    # Refresh the access token.
    # Should be called if the authentication is expired.
    # @raise[Paasal::Errors::OAuth2AuthenticationError] if token refresh failed or authentication never succeeded
    # @return[Paasal::O2AuthClient] current OAuth2Client instance
    def refresh
      if @refresh_token.nil?
        fail Errors::OAuth2AuthenticationError, "Can't refresh token before initial authentication"
      end
      log.debug("Attempt to refresh the access_token with our refresh_token: '#{@refresh_token}'")
      response = post(query: { grant_type: 'refresh_token', refresh_token: @refresh_token })
      extract(body(response))
      self
    end

    private

    def post(params)
      # TODO: use generic http client !?
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
      Excon.new(@auth_url, ssl_verify_peer: @check_certificates).post(request_params)
    rescue Excon::Errors::HTTPStatusError => e
      log.debug "OAuth2 Authentication failed: #{e}"
      case e.response.status
      when 403
        log.error("OAuth2 for '#{@auth_url}' failed with status 403 (access denied), indicating an adapter issue")
        raise Errors::UnknownAdapterCallError, 'Access to resource denied, probably the adapter must be updated'
      when 400, 401
        raise Errors::OAuth2AuthenticationError, body(e.response)[:error_description]
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
      MultiJson.load(response.body, symbolize_keys: true)
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
