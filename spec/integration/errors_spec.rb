require 'spec_helper'
require 'integration/integration_spec_helper'

describe 'API Error schema' do
  context 'GET with invalid accept header' do
    context 'version invalid' do
      before { get '/endpoints', 'HTTP_ACCEPT' => 'application/vnd.paasal-invalidversion' }
      include_examples 'a not accepted request'
    end
    context 'vendor invalid' do
      before { get '/endpoints', 'HTTP_ACCEPT' => 'application/vnd.invalidvendor-v1' }
      include_examples 'a not accepted request'
    end
    context 'content type invalid' do
      before { get '/endpoints', 'HTTP_ACCEPT' => 'application/vnd.paasal-v1+application/xml' }
      include_examples 'a not accepted request'
    end
  end
end
