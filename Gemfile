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

group :development do
  # use patched version to prevent freezing
  gem 'terminal-notifier-guard', git: 'https://github.com/croeck/terminal-notifier-guard.git'
end

group :test do
  # includes required fix for empty arrays as param value, see issue #122 and pull request #125
  gem 'rack-test', git: 'https://github.com/croeck/rack-test.git', branch: 'empty-array-param'
  gem 'rspec-wait'
  gem 'airborne', require: false
  # gem 'codeclimate-test-reporter'
  # testing codeclimate merged reports, see issue https://github.com/codeclimate/ruby-test-reporter/issues/24
  # and pull request https://github.com/codeclimate/ruby-test-reporter/pull/80
  gem 'codeclimate-test-reporter', github: 'grosser/ruby-test-reporter', branch: 'grosser/merge2'
  gem 'factory_girl'
  gem 'faker'
  gem 'simplecov', require: false
end
