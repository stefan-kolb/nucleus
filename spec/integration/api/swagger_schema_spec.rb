require 'spec/integration/integration_spec_helper'

describe 'Swagger schema' do
  context 'with an invalid version can not access' do
    let!(:header) { { 'HTTP_ACCEPT' => 'application/vnd.nucleus-invalidversion' } }

    context 'GET apis' do
      before { get '/schema', header }
      include_examples 'a not accepted request'
    end
    context 'GET endpoints schema' do
      before { get '/schema/endpoints', header }
      include_examples 'a not accepted request'
    end
    context 'GET vendors schema' do
      before { get '/schema/vendors', header }
      include_examples 'a not accepted request'
    end
    context 'GET providers schema' do
      before { get '/schema/providers', header }
      include_examples 'a not accepted request'
    end
  end

  describe 'with a version can access' do
    let!(:header) { { 'HTTP_ACCEPT' => 'application/vnd.nucleus-v1' } }

    context 'GET apis schema' do
      before { get '/schema', header }
      include_examples 'a valid GET request'
    end
    context 'GET endpoints schema' do
      before { get '/schema/endpoints', header }
      include_examples 'a valid GET request'
    end
    context 'GET vendors schema' do
      before { get '/schema/vendors', header }
      include_examples 'a valid GET request'
    end
    context 'GET providers schema' do
      before { get '/schema/providers', header }
      include_examples 'a valid GET request'
    end
  end

  describe 'without a version can access' do
    context 'GET apis schema' do
      before { get '/schema' }
      include_examples 'a valid GET request'
    end
    context 'GET endpoints schema' do
      before { get '/schema/endpoints' }
      include_examples 'a valid GET request'
    end
    context 'GET vendors schema' do
      before { get '/schema/vendors' }
      include_examples 'a valid GET request'
    end
    context 'GET providers schema' do
      before { get '/schema/providers' }
      include_examples 'a valid GET request'
    end
  end
end
