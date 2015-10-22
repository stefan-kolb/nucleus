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
