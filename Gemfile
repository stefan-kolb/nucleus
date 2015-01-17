source 'https://rubygems.org'

# Specify your gem's dependencies in paasal.gemspec
gemspec

gem 'require_all'
gem 'rack'
gem 'grape'
gem 'grape-entity', '0.4.5', :git => 'https://github.com/croeck/grape-entity.git', :branch => 'safe-exposure-of-hash-objects', :require => 'grape-entity'
gem 'grape-swagger'
gem 'thin'
gem 'logger'
gem 'configatron'
gem 'kwalify'
gem 'daybreak'
gem 'filesize'
group :development do
  gem 'yard'
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rack'
  gem 'guard-yard'
  # use patched version to prevent freezing
  gem 'terminal-notifier-guard', :git => 'https://github.com/croeck/terminal-notifier-guard.git'
end

group :test do
  gem 'rake'
  gem 'minitest'
  gem 'airborne'
  gem 'codeclimate-test-reporter', require: nil
  gem 'simplecov'
end