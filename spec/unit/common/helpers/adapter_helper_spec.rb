require 'spec_helper'

describe Paasal::AdapterHelper do
  let!(:adapter) { double('adapter') }
  let!(:oauth2_client) { double('oauth2_client') }
  let!(:calculator) { double('calculator') }
  let!(:helper) { Class.new.extend(Paasal::AdapterHelper) }
  let!(:username) { 'my fictionary user' }
  let!(:password) { 'my fictionary password' }
  before do
    helper.instance_variable_set :@env, 'HTTP_AUTHORIZATION' =>
                                          'Basic ' + ["#{username}:#{password}"].pack('m*').gsub(/\n/, '')

    cache_key = 'a unique cache key!'
    cache_dao = double(Paasal::DB::CacheDao)
    allow_any_instance_of(Paasal::AdapterHelper).to receive(:request_cache) { cache_dao }
    allow(cache_dao).to receive(:get) do |key|
      key.end_with?('adapter') ? adapter : cache_key
    end
    RequestStore.store[:cache_key] = cache_key
    allow(adapter).to receive(:uncache)
    allow(adapter).to receive(:cache)
    allow(adapter).to receive(:cache_key)
  end

  describe '#with_authentication' do
    context 'using OAuth2 authentication' do
      context 'when cache is outdated' do
        before do
          allow(adapter).to receive(:cached) { oauth2_client }
          counted = 0
          expect   = 1
          allow(calculator).to receive(:calc) do
            fail(Paasal::Errors::OAuth2AuthenticationError.new('error', oauth2_client)) if (counted += 1) <= expect
            1
          end
        end

        context 'and refresh was ok' do
          it 'response is returned in repeated call' do
            expect(oauth2_client).to receive(:refresh).once
            expect(calculator).to receive(:calc).exactly(2).times
            helper.with_authentication { calculator.calc }
          end
        end
        context 'and refresh failed' do
          before do
            allow(oauth2_client).to receive(:refresh).and_raise(
              Paasal::Errors::OAuth2AuthenticationError.new('error', oauth2_client))
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

    context 'using custom authentication' do
      context 'when cache is outdated' do
        before do
          calc_counter = 0
          calc_times   = 1
          allow(calculator).to receive(:calc) do
            (calc_counter += 1) <= calc_times ? fail(Paasal::Errors::AuthenticationError, 'error') : 1
          end
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
          it 'the call fails' do
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
      expect(adapter).to receive(:authenticate).once.with(username, password)
      helper.re_authenticate
    end
  end
end
