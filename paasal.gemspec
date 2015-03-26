# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'paasal/version'

Gem::Specification.new do |spec|
  spec.name          = 'paasal'
  spec.version       = Paasal::VERSION
  spec.authors       = ['Cedric Röck']
  spec.email         = ['paasal@roecky.net']
  spec.summary       = 'PaaSal is an abstraction layer for the management functions of '\
                        'Platform-as-a-Service (PaaS) providers.'
  spec.description   = ''
  spec.homepage      = 'https://paasal.github.io/croeck'
  spec.license       = 'MIT'

  # do not include test files, they would tremendously increase the gem size
  # spec.files = `git ls-files -z`.split("\x0") - Dir.glob('spec/adapter/{application-archives,recordings}/**/*')
  # spec.test_files = []

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.require_paths = %w(lib app)
  spec.test_files    = `git ls-files -- spec/*`.split("\n")

  spec.add_runtime_dependency 'configatron', '~> 4.5'
  spec.add_runtime_dependency 'daybreak', '~> 0.3'
  spec.add_runtime_dependency 'em-http-request', '~> 1.1'
  spec.add_runtime_dependency 'excon', '~> 0.44'
  spec.add_runtime_dependency 'faye-websocket', '~> 0.9'
  spec.add_runtime_dependency 'filesize', '~> 0.0'
  spec.add_runtime_dependency 'git', '~> 1.2'
  # TODO: adapt versions once all patches are included in the master branch
  # spec.add_runtime_dependency 'grape', '~> 0.11', '>= 0.11.1'
  # TODO: adapt versions once all patches are included in the master branch
  # spec.add_runtime_dependency 'grape-entity', '~> 0.4', '>= 0.4.5'
  # TODO: adapt versions once all patches are included in the master branch
  # spec.add_runtime_dependency 'grape-swagger', '~> 0.10', '>= 0.10.1'
  spec.add_runtime_dependency 'kwalify', '~> 0.7'
  spec.add_runtime_dependency 'lmdb', '~> 0.4'
  spec.add_runtime_dependency 'logger', '~> 1.2'
  spec.add_runtime_dependency 'mime-types'
  spec.add_runtime_dependency 'moneta', '~> 0.8'
  spec.add_runtime_dependency 'protobuf', '~> 3.4'
  # TODO: adapt versions once all patches are included in the master branch
  # spec.add_runtime_dependency 'rack-stream', '~> 0.0'
  spec.add_runtime_dependency 'request_store', '~> 1.1'
  spec.add_runtime_dependency 'require_all', '~> 1.3'
  spec.add_runtime_dependency 'rubyzip', '~> 1.1'
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
