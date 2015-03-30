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
  describe 'tail request log', :as_cassette, :mock_websocket_on_replay do
    # all tests must be merged into one test, otherwise
    before do
      # TODO: at the time of writing this test, we assume that each platform provides a request log.
      # If this should not be the case, replace the build log with the first element in a queried log list

      get("/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated", request_headers)
      @app = json_body.dup
      # should not be empty due to previous web_url access
      get("/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/logs/request", request_headers)
      @recent = body.dup

      # invoke URL request after x seconds, so that the tailing actually receives new messages
      EM.add_timer(5) do
        live_app = Excon.get(@app[:web_url])
        expect(live_app.status).to eql(200)
      end

      # TODO: use stream capable client to get rid of auto-close via the timeout in env['async.callback.auto.timeout']
      get("/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/logs/request/tail", request_headers)
    end

    include_examples 'a valid GET request'

    it 'is a chunked response message' do
      expect(headers.keys).to include('Transfer-Encoding')
      expect(headers['Transfer-Encoding']).to eql('chunked')
    end

    it 'is encoded as text/plain response message' do
      expect(headers['Content-Type']).to eql('text/plain')
    end

    it 'receives new request log entries' do
      log_entries = body.split("\n")
      recent_entries = @recent.split("\n")
      new_entries = recent_entries - log_entries

      # make sure new request logs appeared in the tailing response
      expect(log_entries.length).to be > recent_entries.length
      expect(new_entries.length).to be > 0
      expect(new_entries.length).to be == log_entries.length - recent_entries.length
    end
  end
end
