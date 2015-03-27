# NOTE: use only 'paasal-test-app-all-updated' as valid app throughout all tests

shared_examples 'log list schema' do
  it 'complies with the log list schema' do
    expect_json_keys(Paasal::API::Models::Logs.documentation.keys)
  end
end

shared_examples 'valid:logs:list' do
  describe 'list logs', :as_cassette do
    before { get "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/logs", request_headers }
    include_examples 'a valid GET request'
    include_examples 'log list schema'
    it 'does contain at least one logfile' do
      expect(json_body[:logs]).not_to eql([])
    end
    it 'contained logfile complies with log entity schema' do
      expect(json_body[:logs][0].keys).to eql(Paasal::API::Models::Log.documentation.keys)
    end
  end

  describe 'list logs fails for non-existing application', :as_cassette do
    before { get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/logs", request_headers }
    include_examples 'an unknown requested resource'
  end
end

# TODO: download build log, content should equal show build log --> test all 3 download formats
# TODO: download all log files, non-empty archive after deployment (!) --> test both download formats
# TODO: tail request log (if available), then fire request, then expect new messages, then kill request.
# Execute within EM.run block? Then use EM.stop

# TODO: shall be retrieved before application deployment
shared_examples 'valid:logs:get:empty' do
  describe 'get empty build log', :as_cassette do
    before do
      # TODO: at the time of writing this test, we assume that each platform provides a build log.
      # If this should not be the case, replace the build log with the first element in a queried log list
      get "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/logs/build", request_headers
    end
    include_examples 'a valid GET request'

    # TODO: response format text/plain or text/html ?!
    # TODO: empty response body
  end
end

shared_examples 'valid:logs:get' do
  describe 'get build log', :as_cassette do
    before do
      # TODO: at the time of writing this test, we assume that each platform provides a build log.
      # If this should not be the case, replace the build log with the first element in a queried log list
      get "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/logs/build", request_headers
    end
    include_examples 'a valid GET request'

    # TODO: response format text/plain or text/html ?!
    # TODO: has entries
  end

  describe 'get log fails for non-existent log_id', :as_cassette do
    before { get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/logs/unknown_id", request_headers }
    include_examples 'an unknown requested resource'
  end
end


shared_examples 'valid:applications:logs:tail' do
  describe 'tail request log', :as_cassette do
    before do
      @app = get("/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated", request_headers)
      @recent = get("/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/logs/request", request_headers)
    end
    it '' do
      # TODO: at the time of writing this test, we assume that each platform provides a request log.
      # If this should not be the case, replace the build log with the first element in a queried log list


      # EM.run do
        # TODO: use streaming capable client
        tail = get "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/logs/request/tail", request_headers
        p "Tail: #{tail}"
        p "Body: #{body}"
        p "Headers: #{headers}"

        # use excon so that the external request is recorded
        @live_app = Excon.get(@app[:web_url])

        # EM.stop
      # end

      # TODO: assertions

    end

    # include_examples 'a valid GET request'

    # TODO: response format text/plain or text/html ?!
    # TODO: new request entries appear
  end
end
