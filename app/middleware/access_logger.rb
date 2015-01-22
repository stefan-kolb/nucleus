require 'rack/body_proxy'
require 'rack/utils'

module Rack
  # Rack::AccessLogger forwards every request to the given +app+, and
  # logs a line to the +logger+.
  #
  # @author Cedric Roeck (cedric.roeck@gmail.com)
  class AccessLogger
    # the log format
    FORMAT = %({%s [%36s] - %s [%s] "%s %s%s %s" %d %s %0.4f\n})

    def initialize(app, logger = nil)
      @app = app
      @logger = logger
    end

    def call(env)
      began_at = Time.now
      # execute app call
      status, header, body = @app.call(env)
      header = Utils::HeaderHash.new(header)
      body = BodyProxy.new(body) { log(env, status, header, began_at) }
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
             request_id,
             env['REMOTE_USER'] || '-',
             ended_at.strftime('%d/%b/%Y:%H:%M:%S %z'),
             env[REQUEST_METHOD],
             env[PATH_INFO],
             env[QUERY_STRING].empty? ? '' : "?#{env[QUERY_STRING]}",
             env['HTTP_VERSION'],
             status.to_s[0..3],
             content_length,
             ended_at - began_at)
    end

    def get_content_length(headers)
      return '-' unless headers[CONTENT_LENGTH]
      content_length = headers[CONTENT_LENGTH]
      content_length.to_s == '0' ? '-' : content_length
    end

    def request_id
      if Thread.current[:paasal_request_id].nil?
        # if there is no request id, then fill up the space
        request_id = '*' * 36
      else
        request_id = Thread.current[:paasal_request_id]
      end
      request_id
    end
  end
end
