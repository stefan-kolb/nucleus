require 'spec/adapter/adapter_spec_helper'

describe 'The PaaSal API' do
  describe 'has the swagger-ui documentation interface which can be accessed at /docs and a GET request' do
    before { get('/docs/index.html') }
    it 'has status 200' do
      expect_status 200
    end
    it 'shows the swagger-ui application title' do
      expect(body).to include('<title>Swagger UI</title>')
    end
    it 'shows the swagger-ui application body' do
      expect(body).to include('swagger-ui-container')
    end
  end
end
