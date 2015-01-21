require 'securerandom'

module Paasal
  module Rack
    # This Rack middleware class assigns the 'HTTP_X_REQUEST_ID'
    # to the current Thread or generates a request ID in the form of
    # a UUID of no request ID was delivered in the request header.
    # The 'X-Request-ID' will also be included in the response header.
    #
    # @author Cedric Roeck (cedric.roeck@gmail.com)
    class RequestId
      def initialize(app)
        @app = app
      end

      def call(env)
        # fetch the ID
        Thread.current[:paasal_request_id] = env['HTTP_X_REQUEST_ID'] || SecureRandom.uuid
        # execute call
        status, headers, body = @app.call(env)
        # assign ID to response headers
        headers['X-Request-ID'] ||= Thread.current[:paasal_request_id]
        [status, headers, body]
      end
    end
  end
end
