source 'https://rubygems.org'

# Specify your gem's dependencies in paasal.gemspec
gemspec

# Patched gems
gem 'grape', git: 'https://github.com/croeck/grape.git',
             branch: 'paasal', require: 'grape'
gem 'grape-entity', '0.4.5', git: 'https://github.com/croeck/grape-entity.git',
                             branch: 'safe-exposure-of-hash-objects', require: 'grape-entity'
gem 'grape-swagger', git: 'https://github.com/croeck/grape-swagger.git',
                     branch: 'required-details-feature', require: 'grape-swagger'

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
