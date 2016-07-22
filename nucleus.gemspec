# coding: utf-8
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'nucleus/version'

Gem::Specification.new do |spec|
  spec.name          = 'nucleus'
  spec.version       = Nucleus::VERSION
  spec.authors       = ['Stefan Kolb', 'Cedric Röck']
  spec.email         = ['stefan.kolb@uni-bamberg.de']
  spec.summary       = 'Nucleus unifies core management functions of Platform-as-a-Service (PaaS) systems.'
  spec.description   = 'Nucleus is a unified API for deployment and management of '\
                        'Platform-as-a-Service (PaaS) systems.'
  spec.homepage      = 'https://github.com/stefan-kolb/nucleus'
  spec.license       = 'MIT'
  spec.executables   = 'nucleus'
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.3'

  # we ignore the test files and icons as they tremendously increase the gem size (up to 43MB)
  spec.files = `git ls-files -z --exclude-standard`.split("\x0").reject do |f|
    f[%r{^(lib/nucleus_api|spec/adapter|icons|docs)/}]
  end
  # again only unit and integration, but no adapter test files
  spec.test_files = spec.files.grep(%r{^(spec)/})

  # used as global configuration
  spec.add_runtime_dependency 'configatron', '~> 4.5'
  # Required for log tailing against HTTP endpoints
  spec.add_runtime_dependency 'em-http-request', '~> 1.1'
  # Used as main HTTP / REST client
  spec.add_runtime_dependency 'excon', '~> 0.44'
  # Required for log tailing against websockets
  spec.add_runtime_dependency 'faye-websocket', '~> 0.9'
  # Application data handling
  spec.add_runtime_dependency 'git', '~> 1.2'
  # Used to build the API
  spec.add_runtime_dependency 'grape', '~> 0.13.0'
  spec.add_runtime_dependency 'grape-entity', '~> 0.4.8', '>= 0.4.5'
  # Used to document the API
  spec.add_runtime_dependency 'grape-swagger', '~> 0.20'
  spec.add_runtime_dependency 'grape-swagger-entity', '~> 0.1'
  # Used to import the vendor, provider & adapter setup from configuration with schema validation
  spec.add_runtime_dependency 'kwalify', '~> 0.7'
  # DB store
  spec.add_runtime_dependency 'lmdb', '~> 0.4'
  # Logging
  spec.add_runtime_dependency 'logger', '~> 1.2'
  # Application archive handling, detect unsupported uploads
  spec.add_runtime_dependency 'mime-types', '~> 2.99'
  # Generic interface for DB store implementations
  spec.add_runtime_dependency 'moneta', '~> 0.8'
  # Openshift logging access and direct Git SSH requests
  spec.add_runtime_dependency 'net-ssh', '~> 3.0'
  # Used for JSON / Hash conversion and test cassette serialization (is way faster than other JSON libs)
  spec.add_runtime_dependency 'oj', '~> 2.14'
  # Required for Cloud Foundry log messages
  spec.add_runtime_dependency 'protobuf', '~> 3.4'
  # To make sure HTTPS is used instead of HTTP
  spec.add_runtime_dependency 'rack-ssl-enforcer', '~> 0.2', '>= 0.2.8'
  # TODO: Should be removed as soon as excon supports multipart requests
  spec.add_runtime_dependency 'rest-client', '~> 1.8'
  # Used to build a streaming API for the log tail action
  spec.add_runtime_dependency 'rack-stream', '= 0.0.5'
  # Save certain information for the current request, e.g. the already loaded adapter
  spec.add_runtime_dependency 'request_store', '~> 1.1'
  # Application setup, require libs
  spec.add_runtime_dependency 'require_all', '~> 1.3'
  # Application data handling
  spec.add_runtime_dependency 'rubyzip', '~> 1.1'
  # Application data handling when using git deployment
  spec.add_runtime_dependency 'sshkey', '~> 1.7'
  # The ONLY supported server ATM
  spec.add_runtime_dependency 'thin', '~> 1.6'
end
