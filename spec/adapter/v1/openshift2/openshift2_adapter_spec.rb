require 'spec/adapter/adapter_spec_helper'

describe Paasal::Adapters::V1::Openshift2Adapter do
  before do
    @endpoint = 'openshift-online'
    @api_version = 'v1'
    @adapter = load_adapter(@endpoint, @api_version)
    @application_region = 'US'
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
    include_examples 'valid:#authenticate'

    # TODO: implement adapter so that tests pass
    # include_examples 'compliant adapter with valid credentials'

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
      end
    end
  end
end
