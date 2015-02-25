require 'spec/adapter/adapter_spec_helper'

describe Paasal::Adapters::V1::CloudControlAdapter do
  before do
    @endpoint = 'cloudcontrol'
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

    describe '#authenticate' do
      before do
        username, password = username_password(@endpoint)
        @cc_token = @adapter.authenticate(username, password)
      end
      it 'does not return nil' do
        expect(@cc_token).to_not be_nil
      end
      it 'does return a CloudControlToken instance' do
        expect(@cc_token).to be_a Paasal::Adapters::V1::CloudControlToken
      end
      it 'has access to an auth header' do
        expect(@cc_token.auth_header).to be_a Hash
      end
      it 'is authenticated' do
        expect(@cc_token.auth_header.keys[0]).to eql 'Authorization'
      end
    end

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
