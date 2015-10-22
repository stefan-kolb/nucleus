shared_examples 'installed service list schema' do
  it 'complies with the installed service list schema' do
    expect_json_keys(Nucleus::API::Models::InstalledServices.documentation.keys)
  end
end

shared_examples 'installed service entity schema' do
  it 'installed service entity schema is compliant' do
    expect_json_keys(Nucleus::API::Models::InstalledService.documentation.keys)
  end
  it 'installed service entity schema for nested properties property is compliant for each array entry' do
    property_keys = Nucleus::API::Models::InstalledServiceProperty.documentation.keys
    json_body[:properties].each do |property|
      expect(property.keys).to include(*property_keys)
    end
  end
end

shared_examples 'valid:applications:services:list:empty' do
  describe 'application services list empty', :as_cassette, cassette_group: 'app-services;list' do
    before { get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services", request_headers }
    include_examples 'a valid GET request'
    include_examples 'installed service list schema'
    it 'does not contain any services' do
      expect(json_body[:services]).to eql([])
    end
  end
end

shared_examples 'valid:applications:services:add' do
  describe 'application services add', cassette_group: 'app-services;add' do
    describe 'succeeds' do
      describe 'with 1st invocation', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services",
               { service: { id: @service[:id] }, plan: { id: @service[:plan_id] } }, request_headers
        end
        include_examples 'a valid POST request'
        include_examples 'installed service entity schema'
      end
    end

    describe 'fails' do
      describe 'if the service is already assigned', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services",
               { service: { id: @service[:id] }, plan: { id: @service[:plan_id] } }, request_headers
        end
        include_examples 'a semantically invalid request'
        it 'bad request refers to already taken name' do
          expect(json_body[:dev_message]).to include('already')
        end
      end
      describe 'with invalid service', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services",
               { service: { id: 'invalid_service_id' }, plan: { id: @service[:plan_id] } }, request_headers
        end
        include_examples 'a semantically invalid request'
      end
      describe 'with invalid plan', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services",
               { service: { id: @service[:id] }, plan: { id: 'invalid_plan_id' } }, request_headers
        end
        include_examples 'a semantically invalid request'
      end
      describe 'with missing service', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services",
               { plan: { id: @service[:plan_id] } }, request_headers
        end
        include_examples 'a bad request'
      end
      describe 'with missing plan', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services",
               { service: { id: @service[:id] } }, request_headers
        end
        include_examples 'a bad request'
      end
    end
  end
end

shared_examples 'valid:applications:services:list' do
  describe 'application services list', cassette_group: 'app-services;list' do
    describe 'succeeds', :as_cassette do
      before { get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services", request_headers }
      include_examples 'a valid GET request'
      include_examples 'installed service list schema'
      it 'does contain 1 service' do
        expect(json_body[:services]).not_to eql([])
        expect(json_body[:services].length).to eql(1)
      end
    end
    describe 'fails for non-existing application', :as_cassette do
      before { get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/services", request_headers }
      include_examples 'an unknown requested resource'
    end
  end
end

shared_examples 'valid:applications:services:get' do
  describe 'application services get', cassette_group: 'app-services;get' do
    describe 'fails' do
      describe 'with non-existent service', :as_cassette do
        before do
          get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services/invalid_service",
              request_headers
        end
        include_examples 'an unknown requested resource'
      end
      describe 'with non-existent application', :as_cassette do
        before do
          get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/services/#{@service[:id]}",
              request_headers
        end
        include_examples 'an unknown requested resource'
      end
    end
    describe 'succeeds', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services/#{@service[:id]}", request_headers
      end
      include_examples 'a valid GET request'
      include_examples 'installed service entity schema'
    end
  end
end

shared_examples 'valid:applications:services:change' do
  describe 'application services change', cassette_group: 'app-services;change' do
    describe 'fails' do
      describe 'with non-existent plan', :as_cassette do
        before do
          patch "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services/#{@service[:id]}",
                { plan: { id: 'an_invalid_service' } }, request_headers
        end
        include_examples 'a semantically invalid request'
      end
      describe 'with non-existent service', :as_cassette do
        before do
          patch "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services/invalid_service",
                { plan: { id: @service[:plan2_id] } }, request_headers
        end
        include_examples 'an unknown requested resource'
      end
      describe 'with non-existent application', :as_cassette do
        before do
          patch "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/services/#{@service[:id]}",
                { plan: { id: @service[:plan2_id] } }, request_headers
        end
        include_examples 'an unknown requested resource'
      end
    end
    describe 'succeeds', :as_cassette do
      before do
        patch "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services/#{@service[:id]}",
              { plan: { id: @service[:plan2_id] } }, request_headers
      end
      include_examples 'a valid PATCH request'
      include_examples 'installed service entity schema'
    end
  end
end

shared_examples 'valid:applications:services:remove' do
  describe 'application services remove', cassette_group: 'app-services;remove' do
    describe 'fails' do
      describe 'with non-existent service', :as_cassette do
        before do
          delete "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services/invalid_service",
                 request_headers
        end
        include_examples 'an unknown requested resource'
      end
      describe 'with non-existent application', :as_cassette do
        before do
          delete "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/services/#{@service[:id]}",
                 request_headers
        end
        include_examples 'an unknown requested resource'
      end
    end
    describe 'succeeds', :as_cassette do
      before do
        delete "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services/#{@service[:id]}",
               request_headers
      end
      include_examples 'a valid DELETE request'
    end
  end
end
