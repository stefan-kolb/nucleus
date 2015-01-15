module Paasal
  module Rack
    # The {Paasal::ErrorRequestLogger} is assigned to redirect the
    # default 'rack.errors' output not only to the console, but also to a log file.
    # This file then includes all error stacktraces.
    #
    # @author Cedric Röck (cedric.roeck@gmail.com)
    class ErrorRequestLogger
      def initialize(app, file)
        @app = app
        @file = file
      end

      def call(env)
        # apply the error logger
        error_logger = ::File.new(@file, 'a+')
        error_logger.sync = true
        env['rack.errors'] =  error_logger
        # execute call
        status, headers, body = @app.call(env)
        # send the response
        [status, headers, body]
      end
    end
  end
end