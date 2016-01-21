module Nucleus
  module API
    module Middleware
      # Nucleus::Middleware::AccessLogger forwards every request to the given +app+, and
      # logs a line to the +logger+.
      #
      # @author Cedric Roeck (cedric.roeck@gmail.com)
      # @since 0.1.0
      class AccessLogger
        # the log format
        FORMAT = %({%s [%36s] - %s [%s] "%s %s%s %s" %d %s %0.4f\n}).freeze

        def initialize(app, logger = nil)
          @app = app
          @logger = logger
        end

        def call(env)
          began_at = Time.now
          # execute app call
          status, header, body = @app.call(env)
          header = ::Rack::Utils::HeaderHash.new(header)
          body = ::Rack::BodyProxy.new(body) { log(env, status, header, began_at) }
          # send response
          [status, header, body]
        end

        private

        def log(env, status, header, began_at)
          log_message = build_message(env, status, header, began_at)

          logger = @logger || env['rack.errors']
          # Standard library logger doesn't support write but it supports << which actually
          # calls to write on the log device without formatting
          if logger.respond_to?(:write)
            logger.write(log_message)
          else
            logger << log_message
          end
        end

        def build_message(env, status, header, began_at)
          ended_at = Time.now
          content_length = get_content_length(header)

          format(FORMAT, env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_ADDR'] || '-',
                 request_id(env),
                 env['REMOTE_USER'] || '-',
                 ended_at.strftime('%d/%b/%Y:%H:%M:%S %z'),
                 env[::Rack::REQUEST_METHOD],
                 env[::Rack::PATH_INFO],
                 env[::Rack::QUERY_STRING].empty? ? '' : "?#{env[::Rack::QUERY_STRING]}",
                 env['HTTP_VERSION'],
                 status.to_s[0..3],
                 content_length,
                 ended_at - began_at)
        end

        def get_content_length(headers)
          return '-' unless headers[::Rack::CONTENT_LENGTH]
          content_length = headers[::Rack::CONTENT_LENGTH]
          content_length.to_s == '0' ? '-' : content_length
        end

        def request_id(env)
          if Thread.current[:nucleus_request_id]
            Thread.current[:nucleus_request_id]
          elsif env.key?('HTTP_X_REQUEST_ID')
            env['HTTP_X_REQUEST_ID']
          else
            # if there is no request id, then fill up the space
            '*' * 36
          end
        end
      end
    end
  end
end
