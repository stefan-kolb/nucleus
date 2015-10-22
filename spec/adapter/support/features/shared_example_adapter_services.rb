shared_examples 'service list schema' do
  it 'complies with the service list schema' do
    expect_json_keys(Nucleus::API::Models::Services.documentation.keys)
  end
end

shared_examples 'service entity schema' do
  it 'complies with the service entity schema' do
    expect_json_keys(Nucleus::API::Models::Service.documentation.keys)
  end
end

shared_examples 'valid:services:get' do
  describe 'services get', cassette_group: 'services;get' do
    describe 'succeeds', :as_cassette do
      before { get "/endpoints/#{@endpoint}/services/#{@service[:id]}", request_headers }
      include_examples 'a valid GET request'
      include_examples 'service entity schema'
    end
    describe 'fails for get of non-existent service', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/services/service_never_exists_0123456789", request_headers
      end
      include_examples 'an unknown requested resource'
    end
  end
end

shared_examples 'valid:services:list' do
  describe 'services list', :as_cassette, cassette_group: 'services;list' do
    before { get "/endpoints/#{@endpoint}/services", request_headers }
    include_examples 'a valid GET request'
    include_examples 'service list schema'
  end
end
