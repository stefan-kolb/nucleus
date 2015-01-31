require 'spec_helper'
require 'integration/integration_spec_helper'

describe Paasal::API::V1::Vendors do
  after { Paasal::TestDataGenerator.clean }

  let!(:vendor_a) { create(:vendor) }
  let!(:vendor_b) { create(:vendor) }
  let!(:provider_a) { create(:provider, vendor: vendor_a.id) }
  let!(:provider_b) { create(:provider, vendor: vendor_a.id) }
  let!(:provider_c) { create(:provider, vendor: vendor_b.id) }
  let!(:endpoint_a) { create(:endpoint, provider: provider_a.id) }
  let!(:endpoint_b) { create(:endpoint, provider: provider_b.id) }

  context 'GET /vendors response' do
    before { get '/vendors' }
    include_examples 'a valid GET request'
    it 'has vendor-list like structure' do
      expect_json_types(size: :int, vendors: :array_of_objects, _links: :object)
    end

    # TODO: contains all required fields

    it 'shows the retrieved number of vendors' do
      expect(json_body[:size]).to eq 2
      expect_json_sizes(vendors: 2)
    end
    it 'lists all vendors' do
      expect(json_body[:vendors][0][:id]).to eq vendor_a.id
      expect(json_body[:vendors][1][:id]).to eq vendor_b.id
    end
  end

  context 'GET /vendors/:id' do
    before { get "/vendors/#{vendor_a.id}" }
    include_examples 'a valid GET request'
    it 'has the structure of an vendor object' do
      expect_json_types(id: :string, name: :string, created_at: :date, updated_at: :date,
                        providers: :array_of_objects, _links: :object)
    end
    it 'contains the requested vendor' do
      expect(json_body[:id]).to eq vendor_a.id
    end
  end
end
