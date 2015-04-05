module Paasal
  module Middleware
    # Paasal::Middleware::RequestId, a rack compatible middleware class, assigns the 'HTTP_X_REQUEST_ID'
    # to the current Thread or generates a request ID in the form of
    # a UUID of no request ID was delivered in the request header.
    # The 'X-Request-ID' will also be included in the response header.
    #
    # @author Cedric Roeck (cedric.roeck@gmail.com)
    # @since 0.1.0
    class RequestId
      def initialize(app)
        @app = app
      end

      def call(env)
        # TODO: handle cascaded requests, id already assigned to the thread !?
        # fetch the ID
        Thread.current[:paasal_request_id] = env['HTTP_X_REQUEST_ID'] || SecureRandom.uuid
        # make sure there is a request id assigned
        env['HTTP_X_REQUEST_ID'] = Thread.current[:paasal_request_id]
        # execute call
        status, headers, body = @app.call(env)
        # assign ID to response headers
        headers = headers.deep_dup if headers.frozen?
        headers['X-Request-ID'] ||= Thread.current[:paasal_request_id]
        [status, headers, body]
      end
    end
  end
end
