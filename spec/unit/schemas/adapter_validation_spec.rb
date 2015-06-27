require 'spec/unit/unit_spec_helper'
require 'kwalify'

describe 'Paasal::Adapters' do
  Paasal::VersionDetector.api_versions.each do |api_version|
    describe "API #{api_version}" do
      it 'has valid adapter requirements' do
        expect(Paasal::API.requirements(api_version)).to_not be_nil
      end

      describe 'configuration' do
        Paasal::Adapters.configuration_files.each do |file|
          adapter_clazz = Paasal::Adapters.adapter_clazz(file, api_version)
          # adapter must not be available for each version (!)
          next unless adapter_clazz
          describe File.basename(file) do
            it 'is a valid adapter configuration' do
              expect(Paasal::VendorParser.parse(file)).to_not be_nil
            end

            let!(:adapter) { adapter_clazz.new 'https://api.example.org' }
            if Paasal::API.requirements(api_version)
              Paasal::API.requirements(api_version).methods.each do |required_method|
                describe "method #{required_method.name}" do
                  it 'is implemented' do
                    expect(adapter).to respond_to(required_method.name)
                  end
                  it 'has required arity' do
                    expect(adapter).to respond_to(required_method.name).with(required_method.arguments).arguments
                  end
                end
              end
            end
          end
        end
      end

      describe 'adapter stub' do
        stub_clazz = Object.const_get('Paasal').const_get('Adapters').const_get(api_version.upcase).const_get('Stub')
        let!(:adapter) { stub_clazz.new 'https://api.example.org' }
        if Paasal::API.requirements(api_version)
          Paasal::API.requirements(api_version).methods.each do |required_method|
            describe "method #{required_method.name}" do
              it 'is implemented' do
                expect(adapter).to respond_to(required_method.name)
              end
              it 'has required arity' do
                expect(adapter).to respond_to(required_method.name).with(required_method.arguments).arguments
              end
            end
          end
        end
      end
    end
  end
end
