require 'base64'

require 'spec/adapter/adapter_spec_helper'

describe Nucleus::Adapters::V1::CloudFoundryV2 do
  before :all do
    @endpoint = 'pivotal'
    # set to valid service and plan id, e.g. bosh-lite: [mongodb, default]
    @service = { id: 'mongolab', plan_id: 'sandbox' }
    @api_version = 'v1'
    @app_min = { original_name: 'nucleus-test-app-min-properties',
                 updated_name: 'nucleus-test-app-min-updated',
                 region: 'default' }
    @app_all = { original_name: 'nucleus-test-app-all-properties',
                 updated_name: 'nucleus-test-app-all-updated',
                 region: 'default' }
    @application_params = { memory: 256.to_i }
    # Cloud Foundry does support the change, but we do not want to change into a payed plan just for testing
    @unsupported = ['with valid credentials is compliant and application services change succeeds',
                    'with valid credentials is compliant and log get with empty results for type request does not contain any log messages', # FIXME: not reliable
                    'with valid credentials is compliant and log download succeeds for type request as .log', # FIXME: may be empty at the moment
                    'with valid credentials is compliant and log download of all logs succeeds as .zip unzipped content equals log content of the show requests', # FIXME: MD5 problems
                    'with valid credentials is compliant and log download of all logs succeeds as .tar.gz unzipped content equals log content of the show requests',
                    'with valid credentials is compliant and log tail request is valid chunked request with encoding and receives at least one new message',
                    'with valid credentials is compliant and deployment data download succeeds for default archive_format .zip', # FIXME: download problem from AWS port 443
                    'with valid credentials is compliant and deployment data download succeeds for archive_format .tar.gz']
  end
  before do |example|
    skip("501 - '#{example.metadata[:full_description]}' is currently not supported by Cloud Foundry V2") if skip_example?(described_class, example.metadata[:full_description], @unsupported)
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
    let!(:request_headers) { { 'HTTP_AUTHORIZATION' => 'Basic ' + Base64.strict_encode64(':') } }
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
        describe 'fails for invalid OPTIONS method' do
          before { options("/endpoints/#{@endpoint}/call/v2/buildpacks", request_headers) }
          include_examples 'valid error schema'
        end
      end
    end
  end
end
