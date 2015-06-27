module Paasal
  module API
    module Middleware
      # The {Paasal::Middleware::BasicAuth} is a layer to handle HTTP Basic authentication in a similar style
      # than Rack itself does. The evaluation returns rack compatible error messages if either credentials are
      # missing (400) or could not be verified (401).<br>
      # The actual verification of the credentials is performed by the authentication block that is passed when
      # initializing this class.
      # @see {::Rack::Auth::Basic}
      #
      # @author Cedric Roeck (cedric.roeck@gmail.com)
      # @since 0.1.0
      class BasicAuth
        include Paasal::API::ErrorBuilder
        include Paasal::Logging

        # Initialize a new instance of the authentication middleware layer.
        # @param [Object] app the rack app to call
        # @param [String] realm the realm to be used for authentication
        # @yield [username, password, params, env] Returns a boolean value whether the passed credentials are
        # accepted by the current endpoint
        # @yieldparam [String] username the username to verify
        # @yieldparam [String] password the password to verify
        # @yieldparam [Hash] params the rack route params, e.g. form inputs such as the :endpoint_id
        # @yieldparam [Hash] env the global rack environment, includes values like the X-Request-ID
        # @yieldreturn [Boolean] true if credentials were verified and are correct, false if they are invalid
        def initialize(app, realm = nil, &authenticator)
          @app = app
          @realm = realm
          @authenticator = authenticator
        end

        def call(env)
          auth = ::Rack::Auth::Basic::Request.new(env)

          return unauthorized('No authentication header provided', env) unless auth.provided?

          return bad_request('Bad authentication request', env) unless auth.basic?

          begin
            # should be either valid or throws an exception
            if valid?(auth, env)
              env['REMOTE_USER'] = auth.username
              return @app.call(env)
            end
            unauthorized('Invalid credentials', env)
          rescue Paasal::Errors::EndpointAuthenticationError => e
            log.debug 'Authentication attempt failed'
            send_response(e.ui_error, e.message, env)
          end
        end

        private

        def unauthorized(dev_msg, env)
          send_response(Paasal::API::ErrorMessages::AUTH_UNAUTHORIZED, dev_msg, env,
                        'WWW-Authenticate' => challenge.to_s)
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

        def valid?(auth, env)
          route_args = env['rack.routing_args']
          @authenticator.call(*auth.credentials << route_args << env)
        end
      end
    end
  end
end
