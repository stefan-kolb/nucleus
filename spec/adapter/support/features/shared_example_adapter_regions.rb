shared_examples 'region list schema' do
  it 'complies with the region list schema' do
    expect_json_keys(Paasal::API::Models::Regions.documentation.keys)
  end
end

shared_examples 'region entity schema' do
  it 'complies with the region entity schema' do
    expect_json_keys(Paasal::API::Models::Region.documentation.keys)
  end
end

shared_examples 'valid:regions:list' do
  describe 'list regions', :as_cassette do
    before { get("/endpoints/#{@endpoint}/regions", request_headers) }
    include_examples 'region list schema'
    include_examples 'a valid GET request'
    it 'does return non empty list' do
      expect(json_body).to_not be_nil
      expect(json_body[:size]).to be >= 1
    end
  end
end

shared_examples 'valid:regions:get' do
  describe 'get region', :as_cassette do
    before { get("/endpoints/#{@endpoint}/regions/#{@app_all[:region]}", request_headers) }
    include_examples 'region entity schema'
    include_examples 'a valid GET request'
  end
end
