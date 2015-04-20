shared_examples 'service plan list schema' do
  it 'complies with the service plan list schema' do
    expect_json_keys(Paasal::API::Models::ServicePlans.documentation.keys)
  end
end

shared_examples 'service plan entity schema' do
  it 'service plan entity schema is compliant' do
    expect_json_keys(Paasal::API::Models::ServicePlan.documentation.keys)
  end
  it 'service plan entity schema for each nested costs property is compliant' do
    json_body[:costs].each do |cost|
      expect(cost.keys).to include(*Paasal::API::Models::ServiceCosts.documentation.keys)
    end
  end
  it 'service plan entity schema for nested costs/prices property and each price is schema compliant' do
    # each price must be conform to the schema
    json_body[:costs].each do |cost|
      cost[:price].each do |price|
        expect(price.keys).to include(*Paasal::API::Models::ServiceCostsPrice.documentation.keys)
      end
    end
  end
end

shared_examples 'valid:services:plans:get' do
  describe 'services plans get', cassette_group: 'application-services-plans;get' do
    describe 'succeeds', :as_cassette do
      before { get "/endpoints/#{@endpoint}/services/#{@service[:id]}/plans/#{@service[:plan_id]}", request_headers }
      include_examples 'a valid GET request'
      include_examples 'service plan entity schema'
    end
    describe 'fails for' do
      describe 'get of service plan with non-existent service', :as_cassette do
        before do
          get "/endpoints/#{@endpoint}/services/service_never_exists_0123456789/plans/#{@service[:plan_id]}",
              request_headers
        end
        include_examples 'an unknown requested resource'
      end

      describe 'get of service plan with non-existent service plan', :as_cassette do
        before do
          get "/endpoints/#{@endpoint}/services/#{@service[:id]}/plans/service_plan_never_exists_0123456789",
              request_headers
        end
        include_examples 'an unknown requested resource'
      end
    end
  end
end

shared_examples 'valid:services:plans:list' do
  describe 'services plans list', cassette_group: 'application-services-plans;list' do
    describe 'succeeds', :as_cassette do
      before { get "/endpoints/#{@endpoint}/services/#{@service[:id]}/plans", request_headers }
      include_examples 'a valid GET request'
      include_examples 'service plan list schema'
    end
    describe 'fails for get of service plan with non-existent service', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/services/service_never_exists_0123456789/plans",
            request_headers
      end
      include_examples 'an unknown requested resource'
    end
  end
end
