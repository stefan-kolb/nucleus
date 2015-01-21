require 'rack/response'

module Paasal
  class Authenticator
    include Paasal::ErrorBuilder

    def initialize(app, realm=nil, &authenticator)
      @app, @realm, @authenticator = app, realm, authenticator
    end

    def call(env)
      auth = ::Rack::Auth::Basic::Request.new(env)

      return unauthorized('No authentication header provided') unless auth.provided?

      return bad_request('Bad authentication request') unless auth.basic?

      if valid?(auth)
        env['REMOTE_USER'] = auth.username

        return @app.call(env)
      end

      unauthorized('Invalid credentials')
    end

    private

    def unauthorized(dev_msg)
      send_response(Paasal::API::ErrorMessages::AUTH_UNAUTHORIZED, dev_msg, { 'WWW-Authenticate' => challenge.to_s })
    end

    def bad_request(dev_msg)
      send_response(Paasal::API::ErrorMessages::AUTH_BAD_REQUEST, dev_msg)
    end

    def send_response(error_msg, dev_msg, additional_headers = {})
      entity = build_error_entity(error_msg, dev_msg)
      msg = API::Models::Error.new(entity).to_json
      options = @app.instance_variable_get(:@app).instance_variable_get(:@options)
      content_types = Grape::ContentTypes.content_types_for(options[:content_types])
      content_type = HashWithIndifferentAccess.new(content_types)[options[:format]]
      headers = { 'Content-Type' => content_type }.merge additional_headers
      ::Rack::Response.new([msg], entity[:status], headers).finish
    end

    def challenge
      'Basic realm="%s"' % @realm
    end

    def valid?(auth)
      route_args = auth.instance_variable_get(:@env)['rack.routing_args']
      @authenticator.call(*auth.credentials << route_args)
    end

  end
end
