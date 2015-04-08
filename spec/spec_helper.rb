$LOAD_PATH << File.join(File.dirname(__FILE__), '..')

# figure out where we are being loaded from
if $LOADED_FEATURES.grep(%r{spec\/spec_helper\.rb}).any?
  begin
    fail 'foo'
  rescue => e
    puts <<-MSG
  ===================================================
  It looks like spec_helper.rb has been loaded
  multiple times. Normalize the require to:

    require "spec/spec_helper"

  Things like File.join and File.expand_path will
  cause it to be loaded multiple times.

  Loaded this time from:

    #{e.backtrace.join("\n    ")}
  ===================================================
    MSG
  end
end

require 'vcr'
require 'factory_girl'
require 'faker'
require 'tmpdir'

# we need this to detect whether to apply test middleware (tailing hack)
ENV['RACK_ENV'] = 'test'

if ENV['CODECLIMATE_REPO_TOKEN']
  require 'simplecov'
  require 'codeclimate-test-reporter'
  SimpleCov.add_filter 'vendor'
  SimpleCov.formatters = []
  SimpleCov.start CodeClimate::TestReporter.configuration.profile
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
# TODO: disable logging via proper config option
configatron.logging.level = Logger::Severity::FATAL
# force tmp database
configatron.db.path = File.join(Dir.tmpdir, "#{SecureRandom.uuid}.paasal.test.store")
configatron.db.delete_on_shutdown = true
configatron.db.override = true

# require our app
require_relative '../scripts/load_app'

# initialize db, versions and auth strategy
require_relative '../scripts/initialize_core'

require_relative 'factories/models.rb'

# require shared examples
require_all 'spec/support'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.before(:suite) do
    Excon.defaults[:mock] = true
  end
  config.after(:each) do
    Excon.stubs.clear
  end
end
