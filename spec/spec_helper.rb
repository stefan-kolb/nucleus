$LOAD_PATH << File.join(__dir__, '..')

# figure out where we are being loaded from
if $LOADED_FEATURES.grep(%r{spec\/spec_helper\.rb}).any?
  begin
    raise 'foo'
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
require 'webmock/rspec'

# we need this to detect whether to apply test middleware (tailing hack)
ENV['RACK_ENV'] = 'test'

require 'simplecov'
# merge results of the last 1 hour
SimpleCov.merge_timeout 3600
SimpleCov.start do
  add_filter 'spec/'
  add_filter 'lib/nucleus/scripts/'
  add_filter 'config/'

  add_group 'Adapters', 'lib/nucleus/adapters'
  add_group 'Core', 'lib/nucleus/core'
  add_group 'Persistence', 'lib/nucleus/persistence'
  add_group 'Lib ext.', 'lib/nucleus/ext'
  add_group 'API versions', 'lib/nucleus_api/api/versions'
  add_group 'API entities', 'lib/nucleus_api/api/entities'
  add_group 'API helpers', 'lib/nucleus_api/api/helpers'
  add_group 'API Middleware', 'lib/nucleus_api/rack_middleware'
  add_group 'API Models', 'lib/nucleus_api/models'
  add_group 'API Lib ext.', 'lib/nucleus_api/ext'
end

# load configuration for integration tests
require 'nucleus/scripts/setup_config'
# disable logging
# TODO: disable logging via proper config option
nucleus_config.logging.level = Logger::Severity::FATAL
# force tmp database
nucleus_config.db.path = File.join(Dir.tmpdir, "#{SecureRandom.uuid}.nucleus.test.store")
nucleus_config.db.delete_on_shutdown = true
nucleus_config.db.override = true

# require our app
require 'nucleus_api/scripts/load_api'

# load the certificate to use for the tests only
nucleus_config.ssh.custom_key = File.expand_path(File.join('spec', 'nucleus_git_key.pem'))

# initialize db, versions and auth strategy
require 'nucleus/scripts/initialize_config_defaults'
# initialize the api config
require 'nucleus_api/scripts/initialize_api_customizations'

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
