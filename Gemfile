source 'https://rubygems.org'

# Specify your gem's dependencies in nucleus.gemspec
gemspec

group :test do
  gem 'airborne', '=0.1.15'
  gem 'codeclimate-test-reporter', require: false
  gem 'factory_girl'
  gem 'faker'
  gem 'memfs'
  # includes required fix for empty arrays as param value, see issue #122 and pull request #125,
  gem 'rack-test', git: 'https://github.com/croeck/rack-test.git', branch: 'empty-array-param'
  gem 'rspec-wait'
  gem 'simplecov', require: false
end

group :development do
  gem 'bundler'
  gem 'guard', '~> 2.13.0'
  # needed for Ruby < 2.2
  gem 'listen', '<= 3.0'
  gem 'guard-bundler'
  gem 'guard-rack'
  gem 'guard-rubocop'
  gem 'guard-yard'
  gem 'inch', '~> 0.7'
  gem 'rake', '~> 10.4'
  gem 'rubocop', '~> 0.37.2'
  gem 'vcr', '~> 3.0'
  gem 'webmock', '~> 1.20'
  gem 'yard', '~> 0.8'
end
