require 'spec/spec_helper'
require 'spec/integration/integration_spec_helper'

describe Nucleus::API::V1::Endpoints do
  after { Nucleus::TestDataGenerator.clean }

  let!(:vendor) { create(:vendor) }
  let!(:provider) { create(:provider, vendor: vendor.id) }
  let!(:endpoint_a) { create(:endpoint, provider: provider.id) }
  let!(:endpoint_b) { create(:endpoint, provider: provider.id) }

  context 'GET /endpoints response' do
    before { get "/providers/#{provider[:id]}/endpoints" }
    include_examples 'a valid GET request'
    it 'has endpoint-list like structure' do
      expect_json_types(size: :int, endpoints: :array_of_objects, _links: :object)
    end
    # # TODO contains all required fields
    # it 'contains all required fields as highlighted in the documentation' do
    #   expect_json_keys('endpoints.0', Nucleus::API::Models::Endpoints.documentation[:items]
    #     .find { |k, v| !!v[:required] } )
    # end
    it 'shows the retrieved number of endpoints' do
      expect(json_body[:size]).to eq 2
      expect_json_sizes(endpoints: 2)
    end
    it 'lists all endpoints' do
      expect(json_body[:endpoints][0][:id]).to eq endpoint_a.id
      expect(json_body[:endpoints][1][:id]).to eq endpoint_b.id
    end
  end

  context 'GET /endpoints/:id' do
    before { get "/endpoints/#{endpoint_a.id}" }
    include_examples 'a valid GET request'
    it 'has the structure of an endpoint object' do
      expect_json_types(id: :string, name: :string, url: :string, created_at: :date,
                        updated_at: :date, _links: :object)
    end
    it 'contains the requested endpoint' do
      expect(json_body[:id]).to eq endpoint_a.id
    end
  end

  context 'DELETE /endpoints/:id' do
    before { delete "/endpoints/#{endpoint_a.id}" }
    include_examples 'a valid DELETE request'

    context 'causes the endpoint list' do
      before { get "/providers/#{provider[:id]}/endpoints" }
      it 'to not include the endpoint anymore' do
        expect(json_body[:size]).to eq 1
        expect_json_sizes(endpoints: 1)
      end
    end
  end

  context 'PATCH /endpoints/:id' do
    let!(:updated_name) { Faker::Internet.slug }
    let!(:updated_url) { Faker::Internet.url }

    context 'with a valid body' do
      before { patch "/endpoints/#{endpoint_a.id}", endpoint: { name: updated_name, url: updated_url } }
      include_examples 'a valid PATCH request'

      context 'causes the endpoint retrieval' do
        before { get "/endpoints/#{endpoint_a.id}" }
        include_examples 'a valid GET request'
        it 'to show the requested resource' do
          expect(json_body[:id]).to eq endpoint_a.id
        end
        it 'to show the updated values' do
          expect(json_body[:name]).to eq updated_name
          expect(json_body[:url]).to eq updated_url
        end
        it 'to show an updated updated_at timestamp' do
          expect(json_body[:updated_at]).to be >= endpoint_a.updated_at
        end
        it 'has the original value of fields that were not changed' do
          expect(json_body[:created_at]).to eq endpoint_a.created_at
        end
      end
    end

    context 'with a partial body' do
      let!(:updated_name) { Faker::Internet.slug }

      before { patch "/endpoints/#{endpoint_a.id}", endpoint: { name: updated_name } }
      include_examples 'a valid PATCH request'

      context 'shows that a repeated endpoint retrieval' do
        before { get "/endpoints/#{endpoint_a.id}" }
        include_examples 'a valid GET request'
        it 'contains the requested resource' do
          expect(json_body[:id]).to eq endpoint_a.id
        end
        it 'contains the updated value' do
          expect(json_body[:name]).to eq updated_name
        end
        it 'has the original value of fields that were not changed' do
          expect(json_body[:url]).to eq endpoint_a.url
        end
      end
    end

    context 'with a malformed body' do
      let!(:updated_name) { Faker::Internet.slug }
      let!(:updated_url) { Faker::Internet.url }
      before { patch "/endpoints/#{endpoint_a.id}", name: updated_name, url: updated_url }
      include_examples 'a bad request'
    end
  end

  context 'POST /providers/:id/endpoints' do
    context 'with a valid body' do
      let!(:ep_name) { Faker::Internet.slug }
      let!(:ep_url) { Faker::Internet.url }
      before { post "/providers/#{provider.id}/endpoints", endpoint: { name: ep_name, url: ep_url } }
      include_examples 'a valid POST request'
      it 'responds with an endpoint object' do
        expect_json_types(id: :string, name: :string, url: :string, created_at: :date,
                          updated_at: :date, _links: :object)
      end

      context 'causes the' do
        context 'endpoint list' do
          before { get "/providers/#{provider[:id]}/endpoints" }
          include_examples 'a valid GET request'
          it 'to include one more endpoint' do
            expect(json_body[:size]).to eq 3
            expect_json_sizes(endpoints: 3)
          end
        end

        context 'endpoint retrieval of the created resource' do
          before { get "/endpoints/#{json_body[:id]}" }
          include_examples 'a valid GET request'
          it 'shows an endpoint with the correct values' do
            expect(json_body[:name]).to eq ep_name
            expect(json_body[:url]).to eq ep_url
          end
        end
      end
    end

    context 'with the body values not nested in an endpoint object' do
      let!(:updated_name) { Faker::Internet.slug }
      let!(:updated_url) { Faker::Internet.url }
      before { post "/providers/#{provider.id}/endpoints", name: updated_name, url: updated_url }
      include_examples 'a bad request'

      context 'causes the endpoint list' do
        before { get "/providers/#{provider[:id]}/endpoints" }
        include_examples 'a valid GET request'
        it 'to not contain more endpoints than before' do
          expect(json_body[:size]).to eq 2
          expect_json_sizes(endpoints: 2)
        end
      end
    end
  end

  context 'when not authenticated' do
    before { get "/endpoints/#{endpoint_a.id}/applications" }
    include_examples 'an unauthorized request'
  end
end
