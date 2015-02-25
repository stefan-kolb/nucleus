require 'spec/adapter/adapter_spec_helper'

describe Paasal::Adapters::V1::CloudFoundryAdapter do
  before do
    @endpoint = 'cf-stackato-local'
    @api_version = 'v1'
    @adapter = load_adapter(@endpoint, @api_version)
    @application_region = 'default'
  end

  context 'with invalid credentials' do
    let!(:request_headers) { credentials(@endpoint, false) }
    include_examples 'invalid:#authenticate'
    include_examples 'compliant adapter with invalid credentials'
  end

  describe 'with missing credentials' do
    let!(:request_headers) { {} }
    include_examples 'compliant adapter with invalid credentials'
  end

  context 'with valid credentials' do
    let!(:request_headers) { credentials(@endpoint) }
    include_examples 'valid: OAuth2 #authenticate'
    include_examples 'compliant adapter with valid credentials'

    describe 'native adapter call' do
      describe 'against endpoint' do
        describe 'does fetch all app usage events' do
          before do
            get "/endpoints/#{@endpoint}/call/v2/app_usage_events", request_headers
          end
          include_examples 'a valid GET request'
          it 'with the specified structure' do
            expect_json_keys(:total_results, :total_pages, :resources)
          end
        end
      end
    end
  end
end