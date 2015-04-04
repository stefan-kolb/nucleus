require 'spec/unit/unit_spec_helper'

describe Paasal::Adapters::OAuth2AuthClient do
  describe 'initialization' do
    it 'applies all values correctly' do
      url = 'theurl'
      check_certs = false
      client = Paasal::Adapters::OAuth2AuthClient.new url, check_certs
      expect(client.instance_variable_get :@auth_url).to be url
      expect(client.verify_ssl).to be check_certs
    end
  end

  describe 'functionality:' do
    subject(:client) { Paasal::Adapters::OAuth2AuthClient.new 'http://localhost', true }
    let!(:invalid_username) { 'invalid_username' }
    let!(:invalid_password) { 'invalid_password' }
    let!(:valid_username) { 'valid_username' }
    let!(:valid_password) { 'valid_password' }
    let!(:valid_refresh_token) { 'valid_refresh_token' }
    let!(:invalid_refresh_token) { 'invalid_refresh_token' }

    before do
      Excon.stub({ query: { grant_type: 'password', username: valid_username, password: valid_password } },
                 body: { access_token: 'access_token', refresh_token: valid_refresh_token,
                         expires_in: 3600, token_type: 'bearer' }.to_json, status: 200)
      Excon.stub({ query: { grant_type: 'password', username: invalid_username, password: invalid_password } },
                 body: { error: 'code', error_description: 'description' }.to_json, status: 401)
      Excon.stub({ query: { grant_type: 'refresh_token', refresh_token: valid_refresh_token } },
                 body: { access_token: 'refreshed_access_token', expires_in: 3600,
                         token_type: 'bearer' }.to_json, status: 200)
      Excon.stub({ query: { grant_type: 'refresh_token', refresh_token: invalid_refresh_token } },
                 body: { error: 'code', error_description: 'description' }.to_json, status: 401)
    end

    context 'when not authenticated' do
      describe '#authenticate' do
        context 'with invalid credentials' do
          it 'raises an error when authentication failed' do
            expect { client.authenticate(invalid_username, invalid_password) }.to raise_error
            Paasal::Errors::AuthenticationError
          end
        end

        context 'with valid credentials' do
          it 'returns the self instance' do
            expect(client.authenticate(valid_username, valid_password))
              .to be_a Paasal::Adapters::OAuth2AuthClient
          end
        end
      end
      describe '#refresh' do
        it 'can not be invoked' do
          expect { client.refresh }.to raise_error
          Paasal::Errors::AuthenticationError
        end
      end
      describe '#auth_header' do
        it 'can not be invoked' do
          expect { client.auth_header }.to raise_error
          Paasal::Errors::AuthenticationError
        end
      end
    end

    context 'when authenticated' do
      before { client.authenticate(valid_username, valid_password) }
      describe '#authenticate' do
        context 'with invalid credentials' do
          before { Excon.stub({}, body: {}, status: 400) }
          it 'returns instance without making new auth request' do
            expect(client.authenticate(valid_username, valid_password)).to be_a Paasal::Adapters::OAuth2AuthClient
          end
        end
        context 'with valid credentials' do
          it 'returns instance without making new auth request' do
            expect(client.authenticate(valid_username, valid_password)).to be_a Paasal::Adapters::OAuth2AuthClient
          end
        end
      end
      describe '#auth_header' do
        context 'when not expired' do
          it 'returns an authorization header' do
            expect(client.auth_header).to have_key('Authorization')
            expect(client.auth_header['Authorization']).to eq 'bearer access_token'
          end
        end
        context 'when expired' do
          before do
            client.instance_variable_set :@expiration, (Time.now - 120)
          end
          it 'returns an updated authorization header' do
            expect(client.auth_header).to have_key('Authorization')
            expect(client.auth_header['Authorization']).to eq 'bearer refreshed_access_token'
          end
        end
      end
      describe '#refresh' do
        before { client.refresh }
        it 'returns the self instance' do
          expect(client.refresh).to be_a Paasal::Adapters::OAuth2AuthClient
        end
        it 'makes an updated authorization header available' do
          expect(client.auth_header).to have_key('Authorization')
          expect(client.auth_header['Authorization']).to eq 'bearer refreshed_access_token'
        end
      end
    end
  end
end
