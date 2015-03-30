require 'rack'

module Paasal
  module Rack
    def self.app(test = false)
      ::Rack::Builder.new do
        #########################
        ### Setup API Loggers ###
        #########################

        # Prepare logging directory
        root = ::File.dirname(__FILE__)
        log_dir = ::File.join(root, 'log')
        FileUtils.mkdir_p(log_dir) unless File.directory?(log_dir)
        # Setup request logging for the past 7 days
        logger = Logger.new(::File.join(root, 'log', 'requests.log'), 'daily', 7)

        #########################
        ### Setup Rack Server ###
        #########################

        if test
          # use this middleware only within tests. It simulates the behavior of EM capable servers within rspec tests
          require 'spec/adapter/helpers/mock_stream_server'
          use MockStreamServer
        end
        use ::Rack::Stream

        # X-Request-ID
        use Paasal::Rack::RequestId

        # Apply request logger, which includes the X-Request-ID
        use ::Rack::AccessLogger, logger

        # log error stacktraces to a dedicated file
        use Paasal::Rack::ErrorRequestLogger, ::File.join('log/error.log')

        # include to deal with environments that do NOT support the DELETE, PATCH, PUT methods
        # use Rack::MethodOverride

        # redirect to the documentation, but do NOT call the index directly
        use ::Rack::Static, urls: { '/docs' => 'redirect.html' }, root: 'public/swagger-ui'
        # we do not want robots to scan our API
        use ::Rack::Static, urls: { '/robots.txt' => 'robots.txt' }, root: 'public'

        run ::Rack::URLMap.new(
          # serve the dynamic API
          '/' => Paasal::API::RootAPI.new,
          '/api' => Paasal::API::RootAPI.new,
          # serves the swagger-ui
          '/docs' => ::Rack::Directory.new('public/swagger-ui')
        )
      end
    end
  end
end
