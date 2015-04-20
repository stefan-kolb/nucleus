require 'spec/adapter/adapter_spec_helper'

describe Paasal::Adapters::V1::CloudControl do
  before :all do
    # skip these example groups / tests for this adapter, both,
    # application update and lifecycle actions are not supported
    @unsupported = ['with valid credentials is compliant and application update',
                    'with valid credentials is compliant and lifecycle operation',
                    'with valid credentials is compliant and deployment succeeds and subsequent',
                    # TODO: currently there are some delays, requests take up to 5min to appear in the log
                    'with valid credentials is compliant and log download succeeds for type request as .log binary',
                    # TODO: currently there are some delays, requests take up to 5min to appear in the log
                    'with valid credentials is compliant and log get of type request does contain at least one',
                    # TODO: currently there are some delays, requests take up to 5min to appear in the log
                    'with valid credentials is compliant and log tail request',
                    # scale-out should work, but the test would require a valid billing address
                    'with valid credentials is compliant and scale-out']
    @endpoint = 'cloudcontrol'
    @api_version = 'v1'
    # we must use these stupid names given that cloud control prohibits special characters and (!)
    # deleted application names are locked for about 48 hours :(
    @app_min = { original_name: 'paasaltestappminproperties21',
                         updated_name: 'paasaltestappminproperties21',
                         region: 'default' }
    @app_all = { original_name: 'paasaltestappallproperties21',
                         updated_name: 'paasaltestappallproperties21',
                         region: 'default' }
  end
  before do |example|
    if skip_example?(described_class, example.metadata[:full_description], @unsupported)
      skip('This feature is currently not supported by cloudControl - 501')
    end
    # reload adapter for each test
    @adapter = load_adapter(@endpoint, @api_version)
  end

  context 'with invalid credentials' do
    let!(:request_headers) { credentials(@endpoint, false) }
    include_examples 'compliant adapter with invalid credentials'
  end

  describe 'with missing credentials' do
    let!(:request_headers) { {} }
    include_examples 'compliant adapter with invalid credentials'
  end

  describe 'with empty credentials' do
    let!(:request_headers) { { 'HTTP_AUTHORIZATION' => 'Basic ' + [':'].pack('m*').gsub(/\n/, '') } }
    include_examples 'compliant adapter with invalid credentials'
  end

  context 'with valid credentials' do
    let!(:request_headers) { credentials(@endpoint) }
    include_examples 'compliant adapter with valid credentials'

    describe 'native adapter call' do
      describe 'against endpoint' do
        describe 'does fetch all available addons' do
          before do
            get "/endpoints/#{@endpoint}/call/addon", request_headers
          end
          include_examples 'a valid GET request'
          it 'with the specified structure' do
            # assumes there is at least one addon
            expect(json_body[0].keys).to include(:name, :stage, :options)
          end
          it 'with the matching content declaration' do
            expect_json_types(:array)
          end
        end
      end
    end
  end
end
