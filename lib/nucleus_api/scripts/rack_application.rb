require 'rack'
require 'rack/body_proxy'
require 'rack/utils'
require 'rack/response'
require 'rack/auth/basic'
require 'rack/ssl-enforcer'

module Nucleus
  module API
    module Rack
      def self.app
        ::Rack::Builder.new do
          #########################
          ### Setup API Loggers ###
          #########################

          # Prepare logging directory
          log_dir = nucleus_config.logging.path
          FileUtils.mkdir_p(log_dir)
          # Setup request logging for the past 7 days
          logger = Logger.new(File.join(log_dir, 'requests.log'), 'daily', 7)

          #########################
          ### Setup Rack Server ###
          #########################

          # Enforce the usage of HTTPS connections
          use ::Rack::SslEnforcer, except_environments: %w(test development)

          # Clear request caches
          use RequestStore::Middleware

          # X-Request-ID
          use Nucleus::API::Middleware::RequestId

          # Apply request logger, which includes the X-Request-ID
          use Nucleus::API::Middleware::AccessLogger, logger

          # log error stacktraces to a dedicated file
          use Nucleus::API::Middleware::ErrorRequestLogger, File.join(log_dir, 'error.log')

          # redirect to the documentation, but do NOT call the index directly
          use ::Rack::Static, urls: { '/docs' => 'redirect.html' }, root: 'public/swagger-ui'
          # we do not want robots to scan our API
          use ::Rack::Static, urls: { '/robots.txt' => 'robots.txt' }, root: 'public'

          run ::Rack::URLMap.new(
            # serve the dynamic API
            '/' => Nucleus::API::RootAPI.new,
            '/api' => Nucleus::API::RootAPI.new,
            # serves the swagger-ui
            '/docs' => ::Rack::Directory.new('public/swagger-ui')
          )
        end
      end
    end
  end
end
