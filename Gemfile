source 'https://rubygems.org'

# Specify your gem's dependencies in paasal.gemspec
gemspec

gem 'require_all'
gem 'rack'
# require fixed version short after 0.10.1
# gem 'grape', :git => 'https://github.com/intridea/grape.git',
# :ref => '567e779e19109de2e5732dd4d12d5713aa6b2edc', :require => 'grape'
gem 'grape'
gem 'grape-entity', '0.4.5', git: 'https://github.com/croeck/grape-entity.git',
                             branch: 'safe-exposure-of-hash-objects', require: 'grape-entity'
gem 'grape-swagger'
gem 'thin'
gem 'logger'
gem 'configatron'
gem 'kwalify'
gem 'daybreak'
gem 'filesize'
gem 'excon'
gem 'request_store'

group :development do
  gem 'yard'
  gem 'rubocop'
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rack'
  gem 'guard-yard'
  gem 'guard-rubocop'
  # use patched version to prevent freezing
  gem 'terminal-notifier-guard', git: 'https://github.com/croeck/terminal-notifier-guard.git'
end

group :test do
  gem 'airborne'
  gem 'codeclimate-test-reporter', require: nil
  gem 'factory_girl'
  gem 'faker'
  gem 'rake'
  gem 'simplecov', require: false
end
