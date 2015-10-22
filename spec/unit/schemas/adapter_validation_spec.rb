require 'spec/unit/unit_spec_helper'
require 'kwalify'

describe 'Nucleus::Adapters' do
  Nucleus::VersionDetector.api_versions.each do |api_version|
    describe "API #{api_version}" do
      it 'has valid adapter requirements' do
        expect(Nucleus::API.requirements(api_version)).to_not be_nil
      end

      describe 'configuration' do
        Nucleus::Adapters.configuration_files.each do |file|
          adapter_clazz = Nucleus::Adapters.adapter_clazz(file, api_version)
          # adapter must not be available for each version (!)
          next unless adapter_clazz
          describe File.basename(file) do
            it 'is a valid adapter configuration' do
              expect(Nucleus::VendorParser.parse(file)).to_not be_nil
            end

            let!(:adapter) { adapter_clazz.new 'https://api.example.org' }
            if Nucleus::API.requirements(api_version)
              Nucleus::API.requirements(api_version).methods.each do |required_method|
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
        stub_clazz = Object.const_get('Nucleus').const_get('Adapters').const_get(api_version.upcase).const_get('Stub')
        let!(:adapter) { stub_clazz.new 'https://api.example.org' }
        if Nucleus::API.requirements(api_version)
          Nucleus::API.requirements(api_version).methods.each do |required_method|
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
