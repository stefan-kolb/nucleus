require 'spec/spec_helper'
require 'nucleus_api/scripts/rack_application'
require 'spec/integration/test_data_generator'
require 'spec/support/shared_example_request_types'
require 'airborne'

# define test suite for coverage report
SimpleCov.command_name 'spec:suite:integration'

Airborne.configure do |config|
  config.rack_app = Nucleus::API::Rack.app
  config.headers = { 'HTTP_ACCEPT' => 'application/vnd.nucleus-v1' }
end

RSpec.configure do |config|
  config.before(:suite) do
    Nucleus::TestDataGenerator.clean
  end

  config.after(:suite) do
    Nucleus::TestDataGenerator.clean
  end

  config.after(:each) do
    Excon.stubs.clear
  end
end
