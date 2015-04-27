source 'https://rubygems.org'

# Specify your gem's dependencies in paasal.gemspec
gemspec

gem 'grape', git: 'https://github.com/intridea/grape.git'

# The pull request has already been made, but the repository is actually dead.
# https://github.com/intridea/rack-stream/pull/6
gem 'rack-stream', git: 'https://github.com/croeck/rack-stream.git',
                   branch: 'lost_connection_callback', require: 'rack-stream'

group :test do
  gem 'airborne'
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
