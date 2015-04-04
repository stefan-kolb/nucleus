require 'spec/adapter/adapter_spec_helper'

describe Paasal::Adapters::V1::CloudControl do
  before :all do
    # TODO: Currently skipping these example groups / tests for this adapter
    @unsupported = ['with valid credentials/is compliant and/valid:applications:lifecycle/lifecycle operations']
    @endpoint = 'cloudcontrol'
    @api_version = 'v1'
    @application_region = 'default'
  end
  before do
    skip('This feature is currently not supported by CloudControl - 501') if skip_example?(self, @unsupported)
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

  context 'with valid credentials' do
    let!(:request_headers) { credentials(@endpoint) }
    # include_examples 'compliant adapter with valid credentials'

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
