require 'spec/unit/unit_spec_helper'

describe Paasal::Provider do
  let(:id) { '67890' }
  let(:name) { 'fake provider name' }
  let(:created_at) { Time.now }
  let(:updated_at) { Time.now.to_s }

  describe 'can be initialized with' do
    context 'an empty hash and' do
      before do
        @provider = Paasal::Provider.new({})
      end
      it 'endpoints are empty' do
        expect(@provider.endpoints).to eql([])
      end
      it 'fields are empty' do
        expect(@provider.id).to be_nil
        expect(@provider.name).to be_nil
        expect(@provider.created_at).to be_nil
        expect(@provider.updated_at).to be_nil
      end
      it 'to_s does not crash' do
        expect { @provider.to_s }.to_not raise_error
      end
    end

    context 'nil and' do
      before do
        @provider = Paasal::Provider.new
      end
      it 'providers are empty' do
        expect(@provider.endpoints).to eql([])
      end
      it 'fields are empty' do
        expect(@provider.id).to be_nil
        expect(@provider.name).to be_nil
        expect(@provider.created_at).to be_nil
        expect(@provider.updated_at).to be_nil
      end
      it 'to_s does not crash' do
        expect { @provider.to_s }.to_not raise_error
      end
    end

    context 'hash properties and endpoint double' do
      before do
        endpoint = instance_double('Paasal::Endpoint', name: 'endpoint name')
        allow(endpoint).to receive(:is_a?).with(Paasal::Endpoint).and_return(true)
        @provider = Paasal::Provider.new('endpoints' => [endpoint], 'id' => id, 'name' => name,
                                         'created_at' => created_at, 'updated_at' => updated_at)
      end
      it 'has one endpoint' do
        expect(@provider.endpoints).to_not eql([])
        expect(@provider.endpoints.length).to eql(1)
      end
      it 'fields are not nil' do
        expect(@provider.id).to_not be_nil
        expect(@provider.name).to_not be_nil
      end
      it 'dates and parent vendor wont be applied' do
        expect(@provider.created_at).to be_nil
        expect(@provider.updated_at).to be_nil
        expect(@provider.vendor).to be_nil
      end
      it 'fields have the valid values assigned' do
        expect(@provider.id).to eql(id)
        expect(@provider.name).to eql(name)
      end
      it 'to_s does not crash' do
        expect { @provider.to_s }.to_not raise_error
      end
    end

    context 'hash properties and endpoint hash' do
      before do
        @provider = Paasal::Provider.new('endpoints' => [{ 'name' => 'endpoint name' }], 'id' => id, 'name' => name,
                                     'created_at' => created_at, 'updated_at' => updated_at)
      end
      it 'has one endpoint' do
        expect(@provider.endpoints).to_not eql([])
        expect(@provider.endpoints.length).to eql(1)
      end
      it 'fields are not nil' do
        expect(@provider.id).to_not be_nil
        expect(@provider.name).to_not be_nil
      end
      it 'dates and parent vendor wont be applied' do
        expect(@provider.created_at).to be_nil
        expect(@provider.updated_at).to be_nil
        expect(@provider.vendor).to be_nil
      end
      it 'fields have the valid values assigned' do
        expect(@provider.id).to eql(id)
        expect(@provider.name).to eql(name)
      end
      it 'to_s does not crash' do
        expect { @provider.to_s }.to_not raise_error
      end
    end
  end
end
