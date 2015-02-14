require 'spec/adapter/support/shared_example_adapter_authentication'
require 'spec/adapter/support/shared_example_adapter_applications'
require 'spec/adapter/support/shared_example_adapter_domains'
require 'spec/adapter/support/shared_example_adapter_vars'

shared_examples 'compliant adapter with valid credentials' do
  describe 'compliant adapter with valid credentials' do
    # application behaviour
    include_examples 'valid:applications:list'
    # include_examples ''
    # include_examples ''
    # domain behaviour
    # env_vars behaviour
  end
end

shared_examples 'compliant adapter with invalid credentials' do
  describe 'compliant adapter with invalid credentials' do
    # application behaviour
    include_examples 'invalid:applications:list'
    # include_examples ''
    # include_examples ''
    # domain behaviour
    # env_vars behaviour
  end
end
