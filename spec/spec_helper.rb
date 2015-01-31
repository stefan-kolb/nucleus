$LOAD_PATH << File.join(File.dirname(__FILE__), '..')

if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
else
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec/'
    add_filter 'scripts/'
    add_filter 'config/'

    add_group 'Adapters', 'app/adapters'
    add_group 'API versions', 'app/api/versions'
    add_group 'API entities', 'app/api/entities'
    add_group 'API helpers', 'app/api/helpers'
    add_group 'Core', 'app/core'
    add_group 'Middleware', 'app/middleware'
    add_group 'Models', 'app/models'
  end
end

# load configuration for integration tests
require_relative '../scripts/load_config'
# disable logging
configatron.logging.level = Logger::Severity::FATAL

# force tmp database
configatron.db.path = "#{Dir.tmpdir}/#{SecureRandom.uuid}.paasal.test.store"
configatron.db.delete_on_shutdown = true
configatron.db.override = true

# require our app
require_relative '../scripts/load_app'

# initialize db, versions and auth strategy
require_relative '../scripts/initialize_core'

# load FactoryGirl
require 'factory_girl'
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
require 'faker'
require_relative 'factories/models.rb'

# require shared examples
require_all 'spec/support'
