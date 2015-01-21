module Paasal
  module Rack
    # The {Paasal::ErrorRequestLogger} is assigned to redirect the
    # default 'rack.errors' output not only to the console, but also to a log file.
    # This file then includes all error stacktraces.
    #
    # @author Cedric Roeck (cedric.roeck@gmail.com)
    class ErrorRequestLogger
      def initialize(app, file)
        @app = app
        @file = file
      end

      def call(env)
        # create the error logger
        error_logger = ::File.new(@file, 'a+')
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
           if logger.respond_to?(:puts)
             logger.puts(msg)
           end
         end
       end

        def write(msg)
          @loggers.each do |logger|
            if logger.respond_to?(:write)
              logger.write(msg)
            end
          end
        end

        def <<(msg)
          @loggers.each do |logger|
            if logger.respond_to?(:<<)
              logger << msg
            end
          end
        end

        def flush
          @loggers.each do |logger|
            if logger.respond_to?(:flush)
              logger.flush
            end
          end
        end

     end
  end
end
