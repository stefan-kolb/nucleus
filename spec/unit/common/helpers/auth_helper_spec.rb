require 'spec_helper'

describe Paasal::Adapters::AuthenticationRetryWrapper do
  let!(:adapter) { double('adapter') }
  let!(:auth_client) { double('auth_client') }
  let!(:calculator) { double('calculator') }
  let!(:user) { 'my fictionary user' }
  let!(:pass) { 'my fictionary password' }
  let!(:fake_env) { { 'HTTP_AUTHORIZATION' => 'Basic ' + ["#{user}:#{pass}"].pack('m*').gsub(/\n/, '') } }
  before do
    cache_key = 'a unique cache key!'
    cache_dao = double(Paasal::DB::CacheDao)
    allow(cache_dao).to receive(:get) do |key|
      key.end_with?('adapter') ? adapter : cache_key
    end
    RequestStore.store[:cache_key] = cache_key
    allow(adapter).to receive(:cache)
    allow(adapter).to receive(:cache_key)
    allow(adapter).to receive(:cached) { auth_client }
  end

  describe '#with_authentication' do
    context 'when cache is outdated' do
      before do
        counted = 0
        expect   = 1
        allow(calculator).to receive(:calc) do
          fail(Paasal::Errors::AuthenticationError.new('error', auth_client)) if (counted += 1) <= expect
          1
        end
      end

      context 'and refresh was ok' do
        it 'response is returned in repeated call' do
          expect(auth_client).to receive(:refresh).once
          expect(calculator).to receive(:calc).exactly(2).times
          Paasal::Adapters::AuthenticationRetryWrapper.with_authentication(adapter, fake_env) { calculator.calc }
        end
      end
      context 'and refresh failed' do
        before do
          allow(auth_client).to receive(:refresh).and_raise(
            Paasal::Errors::AuthenticationError.new('error', auth_client))
        end
        context 'but authentication succeeded' do
          before { allow(adapter).to receive(:authenticate) { 'authentication result' } }
          it 'response is returned in repeated call after the authentication' do
            expect(auth_client).to receive(:authenticate).once
            expect(calculator).to receive(:calc).exactly(2).times
            Paasal::Adapters::AuthenticationRetryWrapper.with_authentication(adapter, fake_env) { calculator.calc }
          end
        end
        context 'and authentication failed' do
          it 'finally fails' do
            expect(auth_client).to receive(:authenticate).once.and_raise(Paasal::Errors::AuthenticationError, 'error')
            expect(calculator).to receive(:calc).exactly(1).times
            expect do
              Paasal::Adapters::AuthenticationRetryWrapper.with_authentication(adapter, fake_env) { calculator.calc }
            end.to raise_error(Paasal::Errors::AuthenticationError)
          end
        end
      end
    end
  end

  describe '#re_authenticate' do
    it 'calls authentication on the adapter' do
      expect(auth_client).to receive(:authenticate).once.with(user, pass)
      Paasal::Adapters::AuthenticationRetryWrapper.re_authenticate(adapter, fake_env)
    end
  end
end
