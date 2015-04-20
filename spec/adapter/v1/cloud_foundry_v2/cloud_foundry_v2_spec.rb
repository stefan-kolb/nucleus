require 'spec/adapter/adapter_spec_helper'

describe Paasal::Adapters::V1::CloudFoundryV2 do
  before :all do
    @endpoint = 'cf-bosh-local'
    @api_version = 'v1'
    @app_min = { original_name: 'paasal-test-app-min-properties',
                 updated_name: 'paasal-test-app-min-updated',
                 region: 'default' }
    @app_all = { original_name: 'paasal-test-app-all-properties',
                 updated_name: 'paasal-test-app-all-updated',
                 region: 'default' }
    @application_params = { memory: 256.to_i }
  end
  before do
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
        describe 'does fetch all buildpacks', :as_cassette do
          before do
            get "/endpoints/#{@endpoint}/call/v2/buildpacks", request_headers
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
