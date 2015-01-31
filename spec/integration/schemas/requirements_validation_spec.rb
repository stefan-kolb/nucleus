require 'spec_helper'
require 'kwalify'

describe 'Paasal::Adapters' do
  Paasal::ApiDetector.api_versions.each do |api_version|
    describe "API #{api_version}" do
      Paasal::Adapters.configuration_files.each do |file|
        adapter_clazz = Paasal::Adapters.adapter_clazz(file, api_version)
        # adapter must not be available for each version (!)
        if adapter_clazz
          describe File.basename(file) do
            let!(:adapter) { adapter_clazz.new 'fake endpoint url' }
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
end
