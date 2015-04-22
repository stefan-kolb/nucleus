source 'https://rubygems.org'

# Specify your gem's dependencies in paasal.gemspec
gemspec

# TODO: Should be removed as soon as excon supports multipart requests
gem 'rest-client'

# Patched gems
gem 'grape', git: 'https://github.com/croeck/grape.git',
             branch: 'paasal', require: 'grape'
gem 'grape-entity', git: 'https://github.com/intridea/grape-entity.git'
gem 'grape-swagger', git: 'https://github.com/croeck/grape-swagger.git',
                     branch: 'paasal', require: 'grape-swagger'
gem 'rack-stream', git: 'https://github.com/croeck/rack-stream.git',
                   branch: 'lost_connection_callback', require: 'rack-stream'

group :test do
  # includes required fix for empty arrays as param value, see issue #122 and pull request #125
  # gem 'rack-test', git: 'https://github.com/croeck/rack-test.git', branch: 'empty-array-param'
  # includes the fix for pull #125 and merging of chunk parts
  gem 'rack-test', git: 'https://github.com/croeck/rack-test.git', branch: 'paasal'
  gem 'rspec-wait'
  gem 'airborne', require: false
  gem 'codeclimate-test-reporter', require: nil
  gem 'factory_girl'
  gem 'faker'
  gem 'simplecov', require: false
  gem 'msgpack'
end
