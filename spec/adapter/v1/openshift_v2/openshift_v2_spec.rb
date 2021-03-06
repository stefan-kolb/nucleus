require 'base64'

require 'spec/adapter/adapter_spec_helper'

describe Nucleus::Adapters::V1::OpenshiftV2 do
  before :all do
    @endpoint = 'openshift-online'
    @api_version = 'v1'
    @app_min = { original_name: 'nucleustestappminproperties',
                 updated_name: 'nucleustestappminproperties',
                 region: 'aws-us-east-1' }
    @app_all = { original_name: 'nucleustestappallproperties',
                 updated_name: 'nucleustestappallproperties',
                 region: 'aws-us-east-1' }
    @unsupported = ['with valid credentials is compliant and application update', # application update is not supported
                    'with valid credentials is compliant and log tail', # log tailing not yet supported
                    # no empty request log
                    'with valid credentials is compliant and log get with empty results for type request',
                    'with valid credentials is compliant and log get of type request',
                    # Openshift V2 does not quite use plans, therefore change is not yet implemented
                    'with valid credentials is compliant and application services change']
    # add mongodb with the default plan
    @service = { id: 'mongodb-2.4', plan_id: 'default' }
  end

  before do |example|
    skip("501 - '#{example.metadata[:full_description]}' is currently not supported by Openshift V2") if skip_example?(described_class, example.metadata[:full_description], @unsupported)
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
    let!(:request_headers) { { 'HTTP_AUTHORIZATION' => 'Basic ' + Base64.strict_encode64(':') } }
    include_examples 'compliant adapter with invalid credentials'
  end

  context 'with valid credentials' do
    let!(:request_headers) { credentials(@endpoint) }
    include_examples 'compliant adapter with valid credentials'

    describe 'native adapter call' do
      describe 'against endpoint' do
        describe 'does fetch all cartridges' do
          before do
            get "/endpoints/#{@endpoint}/call/cartridges", request_headers
          end
          include_examples 'a valid GET request'
          it 'with the specified structure' do
            expect_json_keys(:api_version, :data, :messages, :status, :supported_api_versions, :type, :version)
          end
          it 'with the matching content declaration' do
            expect_json(type: 'cartridges', status: 'ok')
          end
        end
        describe 'fails for invalid OPTIONS method' do
          before { options("/endpoints/#{@endpoint}/call/cartridges", request_headers) }
          include_examples 'valid error schema'
        end
      end
    end
  end
end
