require 'spec/adapter/support/features/shared_example_adapter_authentication'
require 'spec/adapter/support/features/shared_example_adapter_applications'
require 'spec/adapter/support/features/shared_example_adapter_application_data'
require 'spec/adapter/support/features/shared_example_adapter_application_domains'
require 'spec/adapter/support/features/shared_example_adapter_application_lifecycle'
require 'spec/adapter/support/features/shared_example_adapter_application_logs'
require 'spec/adapter/support/features/shared_example_adapter_application_scaling'
require 'spec/adapter/support/features/shared_example_adapter_application_states'
require 'spec/adapter/support/features/shared_example_adapter_application_vars'
require 'spec/adapter/support/features/shared_example_adapter_regions'

shared_examples 'compliant adapter with valid credentials' do
  describe 'is compliant and' do
    # builds an AuthClient
    include_examples 'valid:auth_client'

    # region list and get
    include_examples 'valid:regions:list'
    include_examples 'valid:regions:get'

    # application - create, list, show and update
    include_examples 'valid:applications:create'
    include_examples 'valid:applications:get'
    include_examples 'valid:applications:list'
    include_examples 'valid:applications:update'

    # methods that fail before a deployment has been made
    include_examples 'valid:applications:lifecycle:422'
    include_examples 'valid:applications:data:download:422'
    include_examples 'valid:applications:data:rebuild:422'

    # environment variables
    include_examples 'valid:applications:vars:list:empty'
    include_examples 'valid:applications:vars:create'
    include_examples 'valid:applications:vars:update'
    include_examples 'valid:applications:vars:get'
    include_examples 'valid:applications:vars:list'

    # domains
    include_examples 'valid:applications:domains:list:empty'
    include_examples 'valid:applications:domains:create'
    include_examples 'valid:applications:domains:create:422'
    include_examples 'valid:applications:domains:get'
    include_examples 'valid:applications:domains:list'

    # retrieve an empty log, must be done before deployment (!)
    include_examples 'valid:applications:logs:get:empty'

    # deploy the application data
    include_examples 'valid:applications:data:deploy'

    # lifecycle operations (finally starts the application)
    include_examples 'valid:applications:lifecycle'

    # access the application at its URL
    include_examples 'valid:applications:web'

    # list, get and download log files
    include_examples 'valid:applications:logs:list'
    include_examples 'valid:applications:logs:get'
    include_examples 'valid:applications:logs:download'
    include_examples 'valid:applications:logs:download:all'
    include_examples 'valid:applications:logs:tail'

    # scaling operations
    include_examples 'valid:applications:scale'

    # download the deployed container bits
    include_examples 'valid:applications:data:download'
    include_examples 'valid:applications:data:rebuild'

    # delete operations
    include_examples 'valid:applications:domains:delete'
    include_examples 'valid:applications:vars:delete'
    include_examples 'valid:applications:delete'
  end
end
