require 'scripts/initialize_core'
require 'spec/integration/test_data_generator'

require 'airborne'
Airborne.configure do |config|
  config.rack_app = Paasal::API::RootAPI
  config.headers = { 'HTTP_ACCEPT' => 'application/vnd.paasal-v1' }
end

RSpec.configure do |config|
  config.before(:suite) do
    Paasal::TestDataGenerator.clean
  end

  config.after(:suite) do
    Paasal::TestDataGenerator.clean
  end

  config.before(:each) do
  end

  config.after(:each) do
  end
end
