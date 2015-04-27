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
  # merge results of the last 1 hour
  SimpleCov.merge_timeout 3600
  SimpleCov.start CodeClimate::TestReporter.configuration.profile
else
  require 'simplecov'
  # merge results of the last 1 hour
  SimpleCov.merge_timeout 3600
  SimpleCov.start do
    add_filter 'spec/'
    add_filter 'scripts/'
    add_filter 'config/'

    add_group 'Adapters', 'app/adapters'
    add_group 'API versions', 'app/api/versions'
    add_group 'API entities', 'app/api/entities'
    add_group 'API helpers', 'app/api/helpers'
    add_group 'Core', 'app/core'
    add_group 'Middleware', 'app/rack_middleware'
    add_group 'Models', 'app/models'
    add_group 'Persistence', 'app/persistence'
    add_group 'Lib ext.', 'lib/ext'
  end
end

# load configuration for integration tests
require 'scripts/load_config'
# disable logging
# TODO: disable logging via proper config option
paasal_config.logging.level = Logger::Severity::FATAL
# force tmp database
paasal_config.db.path = File.join(Dir.tmpdir, "#{SecureRandom.uuid}.paasal.test.store")
paasal_config.db.delete_on_shutdown = true
paasal_config.db.override = true

# require our app
require 'scripts/load_app'

# initialize db, versions and auth strategy
require 'scripts/initialize_core'

require 'spec/factories/models'

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
