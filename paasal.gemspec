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

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = %w(lib app)

  spec.add_runtime_dependency 'configatron'
  spec.add_runtime_dependency 'daybreak'
  spec.add_runtime_dependency 'excon'
  spec.add_runtime_dependency 'filesize'
  # spec.add_runtime_dependency 'grape'
  # spec.add_runtime_dependency 'grape-entity'
  # spec.add_runtime_dependency 'grape-swagger'
  spec.add_runtime_dependency 'kwalify'
  spec.add_runtime_dependency 'logger'
  spec.add_runtime_dependency 'request_store'
  spec.add_runtime_dependency 'require_all'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-bundler'
  spec.add_development_dependency 'guard-rack'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'guard-yard'
  spec.add_development_dependency 'inch'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'thin'
  spec.add_development_dependency 'yard'
end
