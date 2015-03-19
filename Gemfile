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

group :development do
  # use patched version to prevent freezing
  gem 'terminal-notifier-guard', git: 'https://github.com/croeck/terminal-notifier-guard.git'
end

group :test do
  # includes required fix for empty arrays as param value, see issue #122 and pull request #125
  gem 'rack-test', git: 'https://github.com/croeck/rack-test.git', branch: 'empty-array-param'
  gem 'rspec-wait'
  gem 'airborne', require: false
  gem 'codeclimate-test-reporter', require: nil
  gem 'factory_girl'
  gem 'faker'
  gem 'simplecov', require: false
end
