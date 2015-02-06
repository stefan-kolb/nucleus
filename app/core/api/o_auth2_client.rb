module Paasal
  class OAuth2Client
    include Paasal::Logging

    def initialize(auth_url, check_certificates = true)
      @auth_url = auth_url
      @check_certificates = check_certificates
    end

    # TODO: documentation
    def authenticate(username, password)
      return self if @access_token
      response = post(query: { grant_type: 'password', username: username, password: password})
      # TODO: throw error if not authenticated
      # TODO: handle certificate errors -> temporary error !?
      # fail Errors::AuthenticationFailedError, 'Endpoint says the credentials are invalid' if response.status == 404
      body = body(response)
      extract(body)
      # refresh token is not included in later updates
      @refresh_token = body[:refresh_token]
      self
    end

    # TODO: documentation
    def auth_header
      if expired?
        # token is expired, renew first
        refresh
      end
      # then return the authorization header
      header
    end

    # TODO: documentation
    def refresh
      if @refresh_token.nil?
        raise Errors::OAuth2AuthenticationError.new("Can't refresh token before initial authentication", self)
      end
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
                         headers: { 'Authorization' => 'Basic Y2Y6' }}.merge(params)
      # execute the post request and return the response
      Excon.new(@auth_url, ssl_verify_peer: @check_certificates).post(request_params)
    rescue Excon::Errors::HTTPStatusError => e
      log.debug "OAuth2 Authentication failed: #{e}"
      case e.response.status
        when 403
          log.error("OAuth2 for '#{@auth_url}' failed with status 403 (access denied), indicating an adapter issue")
          raise Errors::UnknownAdapterCallError.new('Access to resource denied, probably the adapter must be updated')
        when 400, 401
          raise Errors::OAuth2AuthenticationError.new(body(e.response)[:error_description], self)
      end
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
