require 'spec/unit/unit_spec_helper'

describe Paasal::Vendor do
  let(:id) { '12345' }
  let(:name) { 'fake vendor name' }
  let(:created_at) { Time.now }
  let(:updated_at) { Time.now.to_s }

  describe 'can be initialized with' do
    context 'an empty hash and' do
      before do
        @vendor = Paasal::Vendor.new({})
      end
      it 'providers are empty' do
        expect(@vendor.providers).to eql([])
      end
      it 'fields are empty' do
        expect(@vendor.id).to be_nil
        expect(@vendor.name).to be_nil
        expect(@vendor.created_at).to be_nil
        expect(@vendor.updated_at).to be_nil
      end
      it 'to_s does not crash' do
        expect { @vendor.to_s }.to_not raise_error
      end
    end

    context 'nil and' do
      before do
        @vendor = Paasal::Vendor.new
      end
      it 'providers are empty' do
        expect(@vendor.providers).to eql([])
      end
      it 'fields are empty' do
        expect(@vendor.id).to be_nil
        expect(@vendor.name).to be_nil
        expect(@vendor.created_at).to be_nil
        expect(@vendor.updated_at).to be_nil
      end
      it 'to_s does not crash' do
        expect { @vendor.to_s }.to_not raise_error
      end
    end

    context 'hash properties and provider double' do
      before do
        provider = instance_double('Paasal::Provider', name: 'provider name')
        allow(provider).to receive(:is_a?).with(Paasal::Provider).and_return(true)
        @vendor = Paasal::Vendor.new('providers' => [provider], 'id' => id, 'name' => name,
                                     'created_at' => created_at, 'updated_at' => updated_at)
      end
      it 'has one provider' do
        expect(@vendor.providers).to_not eql([])
        expect(@vendor.providers.length).to eql(1)
      end
      it 'fields are not nil' do
        expect(@vendor.id).to_not be_nil
        expect(@vendor.name).to_not be_nil
      end
      it 'dates wont be applied' do
        expect(@vendor.created_at).to be_nil
        expect(@vendor.updated_at).to be_nil
      end
      it 'fields have the valid values assigned' do
        expect(@vendor.id).to eql(id)
        expect(@vendor.name).to eql(name)
      end
      it 'to_s does not crash' do
        expect { @vendor.to_s }.to_not raise_error
      end
    end

    context 'hash properties and provider hash' do
      before do
        @vendor = Paasal::Vendor.new('providers' => [{ 'name' => 'provider name' }], 'id' => id, 'name' => name,
                                     'created_at' => created_at, 'updated_at' => updated_at)
      end
      it 'has one provider' do
        expect(@vendor.providers).to_not eql([])
        expect(@vendor.providers.length).to eql(1)
      end
      it 'fields are not nil' do
        expect(@vendor.id).to_not be_nil
        expect(@vendor.name).to_not be_nil
      end
      it 'dates wont be applied' do
        expect(@vendor.created_at).to be_nil
        expect(@vendor.updated_at).to be_nil
      end
      it 'fields have the valid values assigned' do
        expect(@vendor.id).to eql(id)
        expect(@vendor.name).to eql(name)
      end
      it 'to_s does not crash' do
        expect { @vendor.to_s }.to_not raise_error
      end
    end
  end
end
