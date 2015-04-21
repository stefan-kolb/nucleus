require 'spec/adapter/adapter_spec_helper'

describe Paasal::Adapters::V1::Heroku do
  before :all do
    # skip these example groups / tests for this adapter
    # Heroku does support the change, but we do not want to change into a payed plan just for testing
    @unsupported = ['with valid credentials is compliant and application services change succeeds']
    @endpoint = 'heroku'
    @api_version = 'v1'
    @app_min = { original_name: 'paasal-test-app-min-properties',
                 updated_name: 'paasal-test-app-min-updated',
                 region: 'US' }
    @app_all = { original_name: 'paasal-test-app-all-properties',
                 updated_name: 'paasal-test-app-all-updated',
                 region: 'US' }
    # add mongodb with the free plan (sandbox)
    @service = { id: 'mongolab', plan_id: 'sandbox' }

    VCR.configure do |c|
      c.ignore_request do |request|
        user_agent = request.headers['User-Agent'] ? request.headers['User-Agent'].to_a.first : ''
        # ignore requests to the logging system that are NOT made by Excon (e.g. made by em-http-request)
        request.uri.start_with?('https://logplex.heroku.com/sessions/') && !user_agent.include?('excon')
      end
    end
  end
  before do |example|
    if skip_example?(described_class, example.metadata[:full_description], @unsupported)
      skip("501 - '#{example.metadata[:full_description]}' is currently not supported by Heroku")
    end
    # reload adapter for each test
    @adapter = load_adapter(@endpoint, @api_version)
  end

  context 'with invalid credentials' do
    let!(:request_headers) { credentials(@endpoint, false) }
    include_examples 'compliant adapter with invalid credentials'
  end

  context 'with missing credentials' do
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
        describe 'does fetch account data' do
          before do
            get "/endpoints/#{@endpoint}/call/account", request_headers
          end
          include_examples 'a valid GET request'
          it 'with the specified structure' do
            expect_json_keys(:created_at, :description, :doc_url, :enabled, :id, :name, :state, :updated_at)
          end
        end
      end
    end
  end
end
