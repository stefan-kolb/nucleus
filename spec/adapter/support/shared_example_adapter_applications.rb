shared_examples 'invalid:applications:list' do
  describe 'list applications', :as_cassette do
    before { get "/endpoints/#{@endpoint}/applications", request_headers }
    include_examples 'an unauthorized request'
  end
end

shared_examples 'application list schema' do
  it 'complies with the application list schema' do
    expect_json_keys(Paasal::API::Models::Applications.documentation.keys)
  end
end

shared_examples 'application entity schema' do
  it 'complies with the application entity schema' do
    expect_json_keys(Paasal::API::Models::Application.documentation.keys)
  end
end

shared_examples 'valid:applications:get:404' do
  describe 'get of non-existent application fails', :as_cassette do
    before do
      get "/endpoints/#{@endpoint}/applications/this_app_shall_never_exist_#{SecureRandom.uuid}", request_headers
    end
    include_examples 'an unknown requested resource'
  end
end

shared_examples 'valid:applications:create' do
  describe 'create application fails' do
    describe 'with missing' do
      describe 'name property', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications",
            { application: { runtimes: ['nodejs'] } }, request_headers
        end
        include_examples 'a bad request'
      end
      describe 'runtimes property', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications",
            { application: { name: 'paasal_test_create_with_missing_runtimes' } }, request_headers
        end
        include_examples 'a bad request'
      end
    end
    describe 'with invalid' do
      describe 'region', :as_cassette do
        before do
          application = {
            application: { name: 'paasal_test_create_with_invalid_region', runtimes: [], region: 'anyinvalidregion' }
          }
          post "/endpoints/#{@endpoint}/applications", application, request_headers
        end
        include_examples 'a bad request'
        it 'bad request refers to invalid region' do
          expect(json_body[:dev_message]).to include('anyinvalidregion')
        end
      end
      describe 'runtimes' do
        describe 'by bad URL and unknown name', :as_cassette do
          before do
            application = {
              application: { name: 'paasal_test_create_with_invalid_runtime_name', runtimes: ['youdontknowmert'] }
            }
            post "/endpoints/#{@endpoint}/applications", application, request_headers
          end
          include_examples 'a bad request'
          it 'bad request refers to bad name' do
            expect(json_body[:dev_message]).to include('youdontknowmert')
          end
        end
      end
    end
  end

  describe 'create application' do
    describe 'of type nodejs with all properties', :as_cassette do
      before do
        application = {
          application: {
            name: 'paasal-test-app-all-properties', runtimes: ['nodejs'], region: 'eu', autoscaled: false
          }
        }
        post "/endpoints/#{@endpoint}/applications", application, request_headers
      end
      include_examples 'a valid POST request'
      include_examples 'application entity schema'
    end

    describe 'of type nodejs with minimal properties', :as_cassette do
      before do
        application = { application: { name: 'paasal-test-app-min-properties', runtimes: ['nodejs'] } }
        post "/endpoints/#{@endpoint}/applications", application, request_headers
      end
      include_examples 'a valid POST request'
      include_examples 'application entity schema'
    end
  end
end

shared_examples 'valid:applications:create:422' do
  describe 'create application (repeated) fails with duplicate name', :as_cassette do
    before do
      # repeat create with minimal properties
      application = { application: { name: 'paasal-test-app-min-properties', runtimes: ['nodejs'] } }
      post "/endpoints/#{@endpoint}/applications", application, request_headers
    end
    include_examples 'a semantically invalid request'
  end
end

shared_examples 'valid:applications:get' do
  describe 'get application', :as_cassette do
    # get previously created application
    before { get "/endpoints/#{@endpoint}/applications/paasal-test-app-min-properties", request_headers }
    include_examples 'a valid GET request'
    include_examples 'application entity schema'
  end
end

shared_examples 'valid:applications:list' do
  describe 'list applications', :as_cassette do
    before { get "/endpoints/#{@endpoint}/applications", request_headers }
    include_examples 'a valid GET request'
    include_examples 'application list schema'
  end
end

shared_examples 'valid:applications:update' do
  xit 'update application' do
    # TODO: implement this test
  end
end

shared_examples 'valid:applications:lifecycle:422' do
  describe 'lifecycle operations fail when there is no deployment:' do
    xit 'start fails' do
      # TODO: implement this test
    end
    xit 'stop fails' do
      # TODO: implement this test
    end
    xit 'restart fails' do
      # TODO: implement this test
    end
    xit 'rebuild fails' do
      # TODO: implement this test
    end
  end
end

shared_examples 'valid:applications:download:422' do
  xit 'deployment download fails when there is no deployment' do
    # TODO: implement this test
  end
end

shared_examples 'valid:applications:scaling:422:deployment' do
  xit 'application scaling fails when there is no deployment' do
    # TODO: implement this test
  end
end

shared_examples 'valid:applications:deploy' do
  describe 'deployment of application' do
    xit 'fails for invalid container data' do
      # TODO: implement this test
    end
    xit 'succeeds with valid data' do
      # TODO: implement this test
    end
  end
end

shared_examples 'valid:applications:lifecycle' do
  describe 'lifecycle operation' do
    xit 'stop succeeds' do
      # TODO: implement this test
    end
    xit 'start succeeds' do
      # TODO: implement this test
    end
    xit 'restart succeeds' do
      # TODO: implement this test
    end
    xit 'rebuild succeeds' do
      # TODO: implement this test
    end
  end
end

shared_examples 'valid:applications:download' do
  xit 'deployment data download succeeds' do
    # TODO: implement this test
  end
end

shared_examples 'valid:applications:web' do
  xit 'application can be accessed at its web url' do
    # TODO: implement this test
  end
end

shared_examples 'valid:applications:scaling:in:422:level' do
  xit 'scale-in fails when already on the lowest level' do
    # TODO: implement this test
  end
end

shared_examples 'valid:applications:scaling:out' do
  xit 'scale-out adds one more application instance' do
    # TODO: implement this test
  end
end

shared_examples 'valid:applications:scaling:in' do
  xit 'scale-in removes one application instance' do
    # TODO: implement this test
  end
end

shared_examples 'valid:applications:scaling:down:422:level' do
  xit 'scale-down fails when already on the lowest level' do
    # TODO: implement this test
  end
end

shared_examples 'valid:applications:scaling:up' do
  xit 'scale-up increases the instance level by one' do
    # TODO: implement this test
  end
end

shared_examples 'valid:applications:scaling:down' do
  xit 'scale-down reduces the instance level by one' do
    # TODO: implement this test
  end
end

shared_examples 'valid:applications:delete' do
  xit 'delete application' do
    # TODO: implement this test
  end
end
