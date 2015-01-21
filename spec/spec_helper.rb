$LOAD_PATH<< File.join(File.dirname(__FILE__), '..')

if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
else
  require 'simplecov'
  SimpleCov.start do
    add_group 'Adapters', 'app/adapters'
    add_group 'API versions', 'app/api/versions'
    add_group 'API entities', 'app/api/entities'
    add_group 'API helpers', 'app/api/helpers'
    add_group 'Core', 'app/core'
    add_group 'Middleware', 'app/middleware'
    add_group 'Models', 'app/models'
  end
end

require_relative '../scripts/load_app'
