source 'https://rubygems.org'

# Specify your gem's dependencies in paasal.gemspec
gemspec

group :test do
  gem 'airborne', '=0.1.15'
  gem 'codeclimate-test-reporter', require: nil
  gem 'factory_girl'
  gem 'faker'
  gem 'memfs'
  # includes required fix for empty arrays as param value, see issue #122 and pull request #125,
  # as well as the merging of chunk parts (no pull request made)
  gem 'rack-test', git: 'https://github.com/croeck/rack-test.git', branch: 'paasal'
  gem 'rspec-wait'
  gem 'simplecov', require: false
end
