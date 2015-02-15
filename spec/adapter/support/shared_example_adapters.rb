require 'spec/adapter/support/shared_example_adapter_authentication'
require 'spec/adapter/support/shared_example_adapter_applications'
require 'spec/adapter/support/shared_example_adapter_domains'
require 'spec/adapter/support/shared_example_adapter_vars'
require 'spec/adapter/support/shared_example_adapter_regions'

shared_examples 'compliant adapter with valid credentials' do
  describe 'is compliant and' do
    # TODO: prepare test and delete all applications

    # region list and get
    include_examples 'valid:regions:list'
    include_examples 'valid:regions:get'

    # empty application list
    include_examples 'valid:applications:list'
    # non-existent application
    include_examples 'valid:applications:get:404'
    # create our test application
    include_examples 'valid:applications:create'
    # create and fail with duplicate name
    include_examples 'valid:applications:create:422'
    # get created application
    include_examples 'valid:applications:get'
    # application list with entity
    include_examples 'valid:applications:list'
    # Update application properties
    include_examples 'valid:applications:update'
    # failed lifecycle operations when there is no deployment
    include_examples 'valid:applications:lifecycle:422'
    # can't download bits when no deployment was done before
    include_examples 'valid:applications:download:422'
    # failed scaling operations when there is no deployment
    include_examples 'valid:applications:scaling:422:deployment'

    # empty vars list
    include_examples 'valid:vars:list'
    include_examples 'valid:vars:get:404'
    # create fails with bad arguments
    include_examples 'valid:vars:create'
    include_examples 'valid:vars:update'
    include_examples 'valid:vars:get'
    # vars list with entity
    include_examples 'valid:vars:list'

    # empty domain list
    include_examples 'valid:domains:list'
    include_examples 'valid:domains:get:404'
    # create fails with bad arguments
    include_examples 'valid:domains:create'
    include_examples 'valid:domains:update'
    include_examples 'valid:domains:get'
    # domain list with entity
    include_examples 'valid:domains:list'

    # deploy the application data
    include_examples 'valid:applications:deploy'

    # lifecycle operations
    include_examples 'valid:applications:lifecycle'

    # download the deployed container bits
    include_examples 'valid:applications:download'

    # access the application at its URL
    include_examples 'valid:applications:web'

    # scaling operations
    # fail scale when already on lowest level
    include_examples 'valid:applications:scaling:in:422:level'
    include_examples 'valid:applications:scaling:out'
    include_examples 'valid:applications:scaling:in'
    # fail scale when already on lowest level
    include_examples 'valid:applications:scaling:down:422:level'
    include_examples 'valid:applications:scaling:up'
    include_examples 'valid:applications:scaling:down'

    # delete operations
    include_examples 'valid:domains:delete'
    include_examples 'valid:vars:delete'
    include_examples 'valid:applications:delete'

    # TODO: add log test cases
  end
end

shared_examples 'compliant adapter with invalid credentials' do
  describe 'is compliant and' do
    # TODO: test all endpoints behind the application

    # get the swagger schema that includes all application endpoints
    browser = Rack::Test::Session.new(Rack::MockSession.new(Airborne.configuration.rack_app))
    browser.send('get', '/schema/endpoints', {}, {})
    operations = MultiJson.load(browser.last_response.body, symbolize_keys: true)[:apis].collect do |api|
      if api[:path].include?('/endpoints/{endpoint_id}/')
        { path: api[:path], methods: api[:operations].collect { |operation| operation[:method] } }
      end
    end.compact.flatten

    operations.each do |operation|
      operation[:methods].each do |method|
        # remove format, use default response type
        operation[:path].gsub!(/.{format}/, '')

        describe "#{method}: #{operation[:path]}" do
          before do
            # substitute random IDs for the request query params
            operation[:path].gsub!(/\{endpoint_id}/, @endpoint)
            # substitute random IDs for the request query params
            operation[:path].gsub!(/\{.*?\}/, SecureRandom.uuid)
            # execute the request that shall fail with 401
            get operation[:path], request_headers
          end
          include_examples 'an unauthorized request'
        end
      end
    end
  end
end
