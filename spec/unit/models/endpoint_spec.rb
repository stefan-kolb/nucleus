require 'spec/unit/unit_spec_helper'

describe Nucleus::Endpoint do
  let(:id) { 'a123av6172812' }
  let(:name) { 'fake endpoint name' }
  let(:created_at) { Time.now }
  let(:updated_at) { Time.now.to_s }
  let(:url) { 'api.example.org' }
  let(:app_domain) { 'apps.example.org' }
  let(:trust) { true }

  describe 'can be initialized with' do
    context 'an empty hash and' do
      before do
        @endpoint = Nucleus::Endpoint.new({})
      end
      it 'fields are empty' do
        expect(@endpoint.id).to be_nil
        expect(@endpoint.name).to be_nil
        expect(@endpoint.created_at).to be_nil
        expect(@endpoint.updated_at).to be_nil
        expect(@endpoint.url).to be_nil
        expect(@endpoint.app_domain).to be_nil
      end
      it 'trust is set to false by default' do
        expect(@endpoint.trust).to eql(false)
      end
      it 'to_s does not crash' do
        expect { @endpoint.to_s }.to_not raise_error
      end
    end

    context 'nil and' do
      before do
        @endpoint = Nucleus::Endpoint.new
      end
      it 'fields are empty' do
        expect(@endpoint.id).to be_nil
        expect(@endpoint.name).to be_nil
        expect(@endpoint.created_at).to be_nil
        expect(@endpoint.updated_at).to be_nil
        expect(@endpoint.url).to be_nil
        expect(@endpoint.app_domain).to be_nil
      end
      it 'trust is set to false by default' do
        expect(@endpoint.trust).to eql(false)
      end
      it 'to_s does not crash' do
        expect { @endpoint.to_s }.to_not raise_error
      end
    end

    context 'hash properties' do
      before do
        @endpoint = Nucleus::Endpoint.new('id' => id, 'name' => name, 'created_at' => created_at,
                                         'updated_at' => updated_at, 'trust' => trust, 'app_domain' => app_domain,
                                         'url' => url)
      end
      it 'fields are not nil' do
        expect(@endpoint.id).to_not be_nil
        expect(@endpoint.name).to_not be_nil
        expect(@endpoint.url).to_not be_nil
        expect(@endpoint.app_domain).to_not be_nil
        expect(@endpoint.trust).to_not be_nil
      end
      it 'dates and parent provider wont be applied' do
        expect(@endpoint.created_at).to be_nil
        expect(@endpoint.updated_at).to be_nil
        expect(@endpoint.provider).to be_nil
      end
      it 'fields have the valid values assigned' do
        expect(@endpoint.id).to eql(id)
        expect(@endpoint.name).to eql(name)
        expect(@endpoint.url).to eql(url)
        expect(@endpoint.app_domain).to eql(app_domain)
        expect(@endpoint.trust).to eql(trust)
      end
      it 'to_s does not crash' do
        expect { @endpoint.to_s }.to_not raise_error
      end
    end
  end
end
