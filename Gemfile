source 'https://rubygems.org'

# Specify your gem's dependencies in paasal.gemspec
gemspec

gem 'require_all'
gem 'rack'
gem 'grape'
gem 'grape-swagger'
gem 'thin'
gem 'logger'
gem 'configatron'
gem 'daybreak'
gem 'filesize'
group :development do
  gem 'yard'
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rack'
  gem 'guard-yard'
  # use patched version to prevent freezing
  gem 'terminal-notifier-guard', :git => 'https://github.com/croeck/terminal-notifier-guard'
end

group :test do
  gem 'rake'
  gem 'minitest'
  gem 'airborne'
end