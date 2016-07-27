source 'https://rubygems.org'

# Specify your gem's dependencies in nucleus.gemspec
gemspec

group :test do
  gem 'airborne', '~> 0.2'
  gem 'codeclimate-test-reporter', require: false
  gem 'factory_girl'
  gem 'faker'
  gem 'memfs'
  # includes required fix for empty arrays as param value, see issue #122 and pull request #125,
  gem 'rack-test', git: 'https://github.com/stefan-kolb/rack-test.git', branch: 'empty-array-param'
  # Used to build a streaming API for the log tail action
  gem 'rack-stream', git: 'https://github.com/stefan-kolb/rack-stream.git'
  gem 'rspec-wait'
  gem 'simplecov', require: false
end

group :development do
  gem 'bundler'
  gem 'guard', '~> 2.13'
  gem 'guard-bundler'
  gem 'guard-rack'
  gem 'guard-rubocop'
  gem 'guard-yard'
  gem 'inch', '~> 0.7'
  gem 'rake', '~> 11.1'
  gem 'rubocop', '~> 0.40'
  gem 'vcr', '~> 3.0'
  gem 'webmock', '~> 2.0'
  gem 'yard', '~> 0.8'
end
