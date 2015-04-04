require 'spec/integration/integration_spec_helper'

describe Paasal::API::V1::Auth do
  after { Paasal::TestDataGenerator.clean }

  let!(:vendor_a) { create(:vendor) }
  let!(:vendor_b) { create(:vendor) }
  let!(:provider_a) { create(:provider, vendor: vendor_a.id) }
  let!(:provider_b) { create(:provider, vendor: vendor_b.id) }
  let!(:endpoint_a) { create(:endpoint, provider: provider_a.id) }
  let!(:endpoint_b) { create(:endpoint, provider: provider_b.id) }
  let!(:adapter_a) { create(:adapter, id: endpoint_a.id, adapter_clazz: Paasal::Adapters::V1::Heroku) }
  let!(:adapter_b) { create(:adapter, id: endpoint_b.id, adapter_clazz: Paasal::Adapters::V1::CloudFoundryV2) }

  # tests case when 'use RequestStore::Middleware' was not applied
  context 'With alternating endpoint requests' do
    before do
      allow_any_instance_of(Paasal::Adapters::V1::Heroku).to receive(:auth_client) do
        token_auth = double(Paasal::Adapters::TokenAuthClient)
        allow(token_auth).to receive(:authenticate) { token_auth }
        allow(token_auth).to receive(:auth_header) { { 'Authorization' => 'bearer 1234567890' } }
        token_auth
      end
      allow_any_instance_of(Paasal::Adapters::V1::CloudFoundryV2).to receive(:auth_client) do
        oauth = double(Paasal::Adapters::OAuth2AuthClient)
        allow(oauth).to receive(:authenticate) { oauth }
        allow(oauth).to receive(:auth_header) { { 'Authorization' => 'bearer 0987654321' } }
        allow(oauth).to receive(:refresh) { oauth }
        oauth
      end

      allow_any_instance_of(Paasal::Adapters::V1::Heroku).to receive(:applications).and_wrap_original do |m, _|
        unless m.receiver.send(:headers)['Authorization'] == 'bearer 1234567890'
          fail Paasal::Errors::AuthenticationError, 'Bad authentication credentials'
        end
        []
      end
      call_count = 0
      allow_any_instance_of(Paasal::Adapters::V1::CloudFoundryV2).to receive(:applications).and_wrap_original do |m, _|
        unless m.receiver.send(:headers)['Authorization'] == 'bearer 0987654321'
          fail Paasal::Errors::AuthenticationError, 'Bad authentication credentials'
        end
        call_count += 1
        fail Paasal::Errors::AuthenticationError, 'Fail 1st attempt' if call_count == 1
        []
      end
    end
    it 'credentials are not re-used for different requests' do
      headers_a = { 'HTTP_AUTHORIZATION' => 'Basic ' + ['username_a:password_a'].pack('m*').gsub(/\n/, '') }
      get "/endpoints/#{endpoint_a.id}/applications", headers_a
      expect(response.status).to eq(200)

      headers_b = { 'HTTP_AUTHORIZATION' => 'Basic ' + ['username_b:password_b'].pack('m*').gsub(/\n/, '') }
      get "/endpoints/#{endpoint_b.id}/applications", headers_b
      expect(response.status).to eq(200)
    end
  end
end
