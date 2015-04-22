source 'https://rubygems.org'

# Specify your gem's dependencies in paasal.gemspec
gemspec

# Both, grape and grape-swagger contain a bunch of fixes that are not yet included in the actual project.
# The biggest change is the description of the params via `required_details`.
# TODO: We should create the pull requests and remove the custom repositories as soon as the changes are in the projects
gem 'grape', git: 'https://github.com/croeck/grape.git', branch: 'paasal', require: 'grape'
gem 'grape-swagger', git: 'https://github.com/croeck/grape-swagger.git', branch: 'paasal', require: 'grape-swagger'

# The pull request has already been made, but the repository is actually dead.
# https://github.com/intridea/rack-stream/pull/6
gem 'rack-stream', git: 'https://github.com/croeck/rack-stream.git',
                   branch: 'lost_connection_callback', require: 'rack-stream'

group :test do
  gem 'airborne'
  gem 'codeclimate-test-reporter', require: nil
  gem 'factory_girl'
  gem 'faker'
  gem 'msgpack'
  # includes required fix for empty arrays as param value, see issue #122 and pull request #125,
  # as well as the merging of chunk parts (no pull request made)
  gem 'rack-test', git: 'https://github.com/croeck/rack-test.git', branch: 'paasal'
  gem 'rspec-wait'
  gem 'simplecov', require: false
end
