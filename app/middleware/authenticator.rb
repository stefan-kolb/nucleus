require 'rack/response'

module Paasal
  class Authenticator
    include Paasal::ErrorBuilder

    def initialize(app, realm = nil, &authenticator)
      @app, @realm, @authenticator = app, realm, authenticator
    end

    def call(env)
      auth = ::Rack::Auth::Basic::Request.new(env)

      return unauthorized('No authentication header provided', env) unless auth.provided?

      return bad_request('Bad authentication request', env) unless auth.basic?

      if valid?(auth)
        env['REMOTE_USER'] = auth.username

        return @app.call(env)
      end

      unauthorized('Invalid credentials', env)
    end

    private

    def unauthorized(dev_msg, env)
      send_response(Paasal::API::ErrorMessages::AUTH_UNAUTHORIZED, dev_msg, env, 'WWW-Authenticate' => challenge.to_s)
    end

    def bad_request(dev_msg, env)
      send_response(Paasal::API::ErrorMessages::AUTH_BAD_REQUEST, dev_msg, env)
    end

    def send_response(error_msg, dev_msg, env, additional_headers = {})
      entity = build_error_entity(error_msg, dev_msg)
      msg = API::Models::Error.new(entity).to_json
      options = @app.instance_variable_get(:@app).instance_variable_get(:@options)
      content_types = Grape::ContentTypes.content_types_for(options[:content_types])
      # fallback to json if no content-type was found
      content_type = HashWithIndifferentAccess.new(content_types)[env['api.format'] || options[:format] || :json]
      headers = { 'Content-Type' => content_type }.merge additional_headers
      ::Rack::Response.new([msg], entity[:status], headers).finish
    end

    def challenge
      format('Basic realm="%s"', @realm)
    end

    def valid?(auth)
      route_args = auth.instance_variable_get(:@env)['rack.routing_args']
      @authenticator.call(*auth.credentials << route_args)
    end
  end
end
