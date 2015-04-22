module Paasal
  module Middleware
    # The {Paasal::Middleware::ErrorRequestLogger} is assigned to redirect the
    # default 'rack.errors' output not only to the console, but also to a log file.
    # This file then includes all error stacktraces.
    #
    # @author Cedric Roeck (cedric.roeck@gmail.com)
    # @since 0.1.0
    class ErrorRequestLogger
      def initialize(app, file)
        @app = app
        @file = file
      end

      def call(env)
        # create the error logger
        error_logger = File.new(@file, 'a+')
        error_logger.sync = true
        # assign dispatcher to be used for printing errors
        dispatcher = ErrorRequestDispatcher.new([error_logger, env['rack.errors']])
        env['rack.errors'] = dispatcher
        # execute call
        status, headers, body = @app.call(env)
        # send the response
        [status, headers, body]
      end
    end

    # Dispatch the call (write << puts p pp) to all loggers
    class ErrorRequestDispatcher
      def initialize(loggers)
        @loggers = loggers
      end

      def puts(msg)
        @loggers.each do |logger|
          logger.puts(msg) if logger.respond_to?(:puts)
        end
      end

      def write(msg)
        @loggers.each do |logger|
          logger.write(msg) if logger.respond_to?(:write)
        end
      end

      def <<(msg)
        @loggers.each do |logger|
          logger << msg if logger.respond_to?(:<<)
        end
      end

      def flush
        @loggers.each do |logger|
          logger.flush if logger.respond_to?(:flush)
        end
      end
    end
  end
end
