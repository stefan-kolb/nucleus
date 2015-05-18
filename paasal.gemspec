# coding: utf-8
%w(app config lib).each do |dir|
  abs_dir = File.expand_path("../#{dir}", __FILE__)
  $LOAD_PATH.unshift(abs_dir) unless $LOAD_PATH.include?(abs_dir)
end

require 'paasal/version'

Gem::Specification.new do |spec|
  spec.name          = 'paasal'
  spec.version       = Paasal::VERSION
  spec.authors       = ['Cedric Roeck']
  spec.email         = ['paasal@roecky.net']
  spec.summary       = 'PaaSal is an abstraction layer for the deployment and management functions of '\
                        'Platform-as-a-Service (PaaS) providers.'
  spec.description   = ''
  spec.homepage      = 'https://github.com/croeck/paasal'
  spec.license       = 'TBD'

  spec.executables   = 'paasal'
  spec.require_paths = %w(app config lib)

  # we ignore the test files and icons as they tremendously increase the gem size (up to 43MB)
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f[%r{^(spec/adapter|icons)/}] }
  # again only unit and integration, but no adapter test files
  spec.test_files    = spec.files.grep(%r{^(spec)/})

  # used as global configuration
  spec.add_runtime_dependency 'configatron', '~> 4.5'
  # DB store (1)
  spec.add_runtime_dependency 'daybreak', '~> 0.3'
  # Required for log tailing against HTTP endpoints
  spec.add_runtime_dependency 'em-http-request', '~> 1.1'
  # Used as main HTTP / REST client
  spec.add_runtime_dependency 'excon', '~> 0.44'
  # Required for log tailing against websockets
  spec.add_runtime_dependency 'faye-websocket', '~> 0.9'
  # Application data handling
  spec.add_runtime_dependency 'git', '~> 1.2'
  # TODO: adapt versions once all patches are included in the master branch
  # Used to build the API
  # spec.add_runtime_dependency 'grape', '~> 0.11', '>= 0.11.1'
  spec.add_runtime_dependency 'grape-entity', '~> 0.4', '>= 0.4.5'
  # Used to document the API
  spec.add_runtime_dependency 'grape-swagger', '~> 0.10', '>= 0.10.1'
  # Used to import the vendor, provider & adapter setup from configuration with schema validation
  spec.add_runtime_dependency 'kwalify', '~> 0.7'
  # DB store (2)
  spec.add_runtime_dependency 'lmdb', '~> 0.4'
  # Logging
  spec.add_runtime_dependency 'logger', '~> 1.2'
  # Application archive handling, detect unsupported uploads
  spec.add_runtime_dependency 'mime-types', '~> 2.4'

  # Generic interface for DB store implementations
  spec.add_runtime_dependency 'moneta', '~> 0.8'
  # Openshift logging access and direct Git SSH requests
  spec.add_runtime_dependency 'net-ssh'
  # Used for JSON / Hash conversion and test cassette serialization (is way faster than other JSON libs)
  spec.add_runtime_dependency 'oj'
  # Required for Cloud Foundry log messages
  spec.add_runtime_dependency 'protobuf', '~> 3.4'
  # To make sure HTTPS is used instead of HTTP
  spec.add_runtime_dependency 'rack-ssl-enforcer', '>= 0.2.8'
  # TODO: Should be removed as soon as excon supports multipart requests
  spec.add_runtime_dependency 'rest-client', '~> 1.8'

  # TODO: adapt versions once all patches are included in the master branch
  # Used to build a streaming API for the log tail action
  # spec.add_runtime_dependency 'rack-stream', '~> 0.0'
  # Save certain information for the current request, e.g. the already loaded adapter
  spec.add_runtime_dependency 'request_store', '~> 1.1'
  # Application setup, require libs
  spec.add_runtime_dependency 'require_all', '~> 1.3'
  # Application data handling
  spec.add_runtime_dependency 'rubyzip', '~> 1.1'
  # Application data handling when using git deployment
  spec.add_runtime_dependency 'sshkey', '~> 1.6.1'
  # The ONLY supported server ATM
  spec.add_runtime_dependency 'thin', '~> 1.6'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-bundler'
  spec.add_development_dependency 'guard-rack'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'guard-yard'
  spec.add_development_dependency 'inch'
  spec.add_development_dependency 'rake', '~> 10.4'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'vcr', '~> 2.9'
  spec.add_development_dependency 'webmock', '~> 1.20'
  spec.add_development_dependency 'yard', '~> 0.8'
end
