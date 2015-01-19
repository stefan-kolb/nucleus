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

      return bad_request unless auth.basic?

      if valid?(auth)
        env['REMOTE_USER'] = auth.username

        return @app.call(env)
      end

      unauthorized('Invalid credentials')
    end


    private

    def unauthorized(dev_msg)
      entity = build_error_entity(Paasal::API::ErrorMessages::AUTH_UNAUTHORIZED, dev_msg)
      msg = API::Models::Error.new(entity).to_json

      options = @app.instance_variable_get(:@app).instance_variable_get(:@options)
      content_types = Grape::ContentTypes.content_types_for(options[:content_types])
      content_type = HashWithIndifferentAccess.new(content_types)[options[:format]]
      ::Rack::Response.new([msg], entity[:status], {
                                               'Content-Type' => content_type,
                                               'WWW-Authenticate' => challenge.to_s}).finish
    end

    def bad_request
      entity = env['api.endpoint'].build_error_entity(Paasal::API::ErrorMessages::AUTH_BAD_REQUEST, "custom dev message")

      [ Paasal::API::ErrorMessages::AUTH_BAD_REQUEST[:status],
        { ::Rack::CONTENT_TYPE => 'text/plain',
          ::Rack::CONTENT_LENGTH => '0' },
        []
      ]

      ::Rack::Response.new([message], status, headers).finish
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
