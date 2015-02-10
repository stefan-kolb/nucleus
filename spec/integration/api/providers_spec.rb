require 'spec_helper'
require 'integration/integration_spec_helper'

describe Paasal::API::V1::Providers do
  after { Paasal::TestDataGenerator.clean }

  let!(:vendor) { create(:vendor) }
  let!(:provider_a) { create(:provider, vendor: vendor.id) }
  let!(:provider_b) { create(:provider, vendor: vendor.id) }
  let!(:endpoint_a) { create(:endpoint, provider: provider_a.id) }
  let!(:endpoint_b) { create(:endpoint, provider: provider_a.id) }
  let!(:endpoint_c) { create(:endpoint, provider: provider_b.id) }

  describe 'GET /vendors/:vendor_id/providers response' do
    before { get "/vendors/#{vendor.id}/providers" }
    include_examples 'a valid GET request'
    it 'has provider-list like structure' do
      expect_json_types(size: :int, providers: :array_of_objects, _links: :object)
    end

    # TODO: contains all required fields

    it 'shows the retrieved number of providers' do
      expect(json_body[:size]).to eq 2
      expect_json_sizes(providers: 2)
    end
    it 'lists all providers' do
      expect(json_body[:providers][0][:id]).to eq provider_a.id
      expect(json_body[:providers][1][:id]).to eq provider_b.id
    end
  end

  describe 'GET /vendors/:vendor_id/providers response (repeated)' do
    before do
      get "/vendors/#{vendor.id}/providers"
      # 2nd call, previous issue caused providers the be shown only once
      get "/vendors/#{vendor.id}/providers"
    end
    include_examples 'a valid GET request'
    it 'has provider-list like structure' do
      expect_json_types(size: :int, providers: :array_of_objects, _links: :object)
    end

    # TODO: contains all required fields

    it 'shows the retrieved number of providers' do
      expect(json_body[:size]).to eq 2
      expect_json_sizes(providers: 2)
    end
    it 'lists all providers' do
      expect(json_body[:providers][0][:id]).to eq provider_a.id
      expect(json_body[:providers][1][:id]).to eq provider_b.id
    end
  end

  describe 'GET /providers/:id' do
    before { get "/providers/#{provider_a.id}" }
    include_examples 'a valid GET request'
    it 'has the structure of an provider object' do
      expect_json_types(id: :string, name: :string, created_at: :date, updated_at: :date,
                        endpoints: :array_of_objects, _links: :object)
    end
    it 'contains the requested provider' do
      expect(json_body[:id]).to eq provider_a.id
    end
  end

  describe 'DELETE /providers/:id' do
    before { delete "/providers/#{provider_a.id}" }
    include_examples 'a valid DELETE request'

    describe 'proves that the provider list' do
      before { get "/vendors/#{vendor.id}/providers" }
      it 'does not include the provider anymore' do
        expect(json_body[:size]).to eq 1
        expect_json_sizes(providers: 1)
      end
    end
  end

  describe 'PATCH /providers/:id' do
    let!(:updated_name) { Faker::Internet.slug }

    context 'with a valid body' do
      before { patch "/providers/#{provider_a.id}", provider: { name: updated_name } }
      include_examples 'a valid PATCH request'

      describe 'proves that the provider retrieval' do
        before { get "/providers/#{provider_a.id}" }
        include_examples 'a valid GET request'
        it 'shows the requested resource' do
          expect(json_body[:id]).to eq provider_a.id
        end
        it 'shows the updated values' do
          expect(json_body[:name]).to eq updated_name
        end
        it 'shows an updated updated_at timestamp' do
          expect(json_body[:updated_at]).to be >= provider_a.updated_at
        end
        it 'has the original value of fields that were not changed' do
          expect(json_body[:created_at]).to eq provider_a.created_at
        end
      end
    end

    context 'with a malformed body' do
      let!(:updated_name) { Faker::Internet.slug }
      before { patch "/providers/#{provider_a.id}", name: updated_name }
      include_examples 'a bad request'
    end
  end

  describe 'POST /vendors/:id/providers' do
    context 'with a valid body' do
      let!(:p_name) { Faker::Internet.slug }
      before { post "/vendors/#{vendor.id}/providers", provider: { name: p_name } }
      include_examples 'a valid POST request'
      it 'responds with a provider object' do
        expect_json_types(id: :string, name: :string, created_at: :date, updated_at: :date,
                          endpoints: :array_of_objects, _links: :object)
      end

      describe 'proves that the' do
        describe 'provider list' do
          before { get "/vendors/#{vendor.id}/providers" }
          include_examples 'a valid GET request'
          it 'includes one additional provider' do
            expect(json_body[:size]).to eq 3
            expect_json_sizes(providers: 3)
          end
        end

        describe 'provider retrieval of the created resource' do
          before { get "/providers/#{json_body[:id]}" }
          include_examples 'a valid GET request'
          it 'shows a provider with the correct values' do
            expect(json_body[:name]).to eq p_name
          end
        end
      end
    end

    context 'with the body values not nested in a provider object' do
      let!(:updated_name) { Faker::Internet.slug }
      before { post "/vendors/#{vendor.id}/providers", name: updated_name }
      include_examples 'a bad request'

      context 'proves that the provider list' do
        before { get "/vendors/#{vendor.id}/providers" }
        include_examples 'a valid GET request'
        it 'does not contain more providers than before' do
          expect(json_body[:size]).to eq 2
          expect_json_sizes(providers: 2)
        end
      end
    end
  end
end
