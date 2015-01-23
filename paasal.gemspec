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
  spec.homepage      = 'paasal.github.io/croeck'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = %w(lib app)

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
