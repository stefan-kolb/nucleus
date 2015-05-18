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
    add_filter 'lib/paasal/scripts/'
    add_filter 'config/'

    add_group 'Adapters', 'lib/paasal/adapters'
    add_group 'API versions', 'lib/paasal/api/versions'
    add_group 'API entities', 'lib/paasal/api/entities'
    add_group 'API helpers', 'lib/paasal/api/helpers'
    add_group 'Core', 'lib/paasal/core'
    add_group 'Middleware', 'lib/paasal/rack_middleware'
    add_group 'Models', 'lib/paasal/models'
    add_group 'Persistence', 'lib/paasal/persistence'
    add_group 'Lib ext.', 'lib/paasal/ext'
  end
end

# load configuration for integration tests
require 'paasal/scripts/setup_config'
# disable logging
# TODO: disable logging via proper config option
paasal_config.logging.level = Logger::Severity::FATAL
# force tmp database
paasal_config.db.path = File.join(Dir.tmpdir, "#{SecureRandom.uuid}.paasal.test.store")
paasal_config.db.delete_on_shutdown = true
paasal_config.db.override = true

# require our app
require 'paasal/scripts/load'

# load the certificate to use for the tests only
paasal_config.ssh.custom_key = File.expand_path(File.join('spec', 'paasal_git_key.pem'))

# initialize db, versions and auth strategy
require 'paasal/scripts/initialize_core'

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
