require 'spec_helper'
require 'integration/integration_spec_helper'

describe 'API Error schema' do
  context 'GET with invalid accept header' do
    context 'version invalid' do
      let!(:header) { { 'HTTP_ACCEPT' => 'application/vnd.paasal-invalidversion' } }

      context 'for valid endpoint' do
        before { get '/vendors', header }
        include_examples 'a not accepted request'
      end

      context 'for an invalid endpoint' do
        before { get '/vendorsdreamcomestrue', header }
        include_examples 'an unknown requested resource'
      end
    end
    context 'vendor invalid' do
      let!(:header) { { 'HTTP_ACCEPT' => 'application/vnd.invalidvendor-v1' } }

      context 'for valid endpoint' do
        before { get '/vendors', header }
        include_examples 'a not accepted request'
      end

      context 'for an invalid endpoint' do
        before { get '/vendorsdreamcomestrue', header }
        include_examples 'an unknown requested resource'
      end
    end
    context 'content type invalid' do
      before { get '/vendors', 'HTTP_ACCEPT' => 'application/vnd.paasal-v1+application/xml' }
      include_examples 'a not accepted request'
    end
  end
  context 'GET with missing accept header' do
    context 'for valid endpoint' do
      before { get '/vendors' }
      include_examples 'a valid GET request'
    end

    context 'for an invalid endpoint' do
      before { get '/vendorsdreamcomestrue' }
      include_examples 'an unknown requested resource'
    end
  end
end
