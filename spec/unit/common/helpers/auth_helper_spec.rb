require 'spec_helper'

describe Paasal::AuthHelper do
  let!(:adapter) { double('adapter') }
  let!(:auth_client) { double('auth_client') }
  let!(:calculator) { double('calculator') }
  let!(:helper) { Class.new.extend(Paasal::AuthHelper) }
  let!(:user) { 'my fictionary user' }
  let!(:pass) { 'my fictionary password' }
  before do
    helper.instance_variable_set :@env, 'HTTP_AUTHORIZATION' => 'Basic ' + ["#{user}:#{pass}"].pack('m*').gsub(/\n/, '')
    allow(helper).to receive(:adapter) { adapter }

    cache_key = 'a unique cache key!'
    cache_dao = double(Paasal::DB::CacheDao)
    allow_any_instance_of(Paasal::AuthHelper).to receive(:request_cache) { cache_dao }
    allow(cache_dao).to receive(:get) do |key|
      key.end_with?('adapter') ? adapter : cache_key
    end
    RequestStore.store[:cache_key] = cache_key
    allow(adapter).to receive(:uncache)
    allow(adapter).to receive(:cache)
    allow(adapter).to receive(:cache_key)
  end

  describe '#with_authentication' do
    context 'when cache is outdated' do
      before do
        allow(adapter).to receive(:cached) { auth_client }
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
          helper.with_authentication { calculator.calc }
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
            expect(adapter).to receive(:authenticate).once
            expect(calculator).to receive(:calc).exactly(2).times
            helper.with_authentication { calculator.calc }
          end
        end
        context 'and authentication failed' do
          it 'finally fails' do
            expect(adapter).to receive(:authenticate).once.and_raise(Paasal::Errors::AuthenticationError, 'error')
            expect(calculator).to receive(:calc).exactly(1).times
            expect { helper.with_authentication { calculator.calc } }
              .to raise_error(Paasal::Errors::AuthenticationError)
          end
        end
      end
    end
  end

  describe '#re_authenticate' do
    it 'invalidates the cache' do
      allow(adapter).to receive(:authenticate)
      expect(adapter).to receive(:uncache).once.with('a unique cache key!')
      helper.re_authenticate
    end
    it 'calls authentication on the adapter' do
      allow(adapter).to receive(:uncache)
      expect(adapter).to receive(:authenticate).once.with(user, pass)
      helper.re_authenticate
    end
  end
end
