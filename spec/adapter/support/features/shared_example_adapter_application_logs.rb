# NOTE: use only 'paasal-test-app-all-updated' as valid app throughout all tests

shared_examples 'log list schema' do
  it 'complies with the log list schema' do
    expect_json_keys(Paasal::API::Models::Logs.documentation.keys)
  end
end
shared_examples 'a valid log encoding' do
  it 'is encoded as text/plain response message' do
    expect(headers['Content-Type']).to eql('text/plain')
  end
end

shared_examples 'valid:logs:list' do
  describe 'logs list' do
    describe 'succeeds', :as_cassette do
      before { get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs", request_headers }
      include_examples 'a valid GET request'
      include_examples 'log list schema'
      it 'does contain at least one logfile' do
        expect(json_body[:logs]).not_to eql([])
      end
      it 'contained logfile complies with log entity schema' do
        expect(json_body[:logs][0].keys).to eql(Paasal::API::Models::Log.documentation.keys)
      end
    end

    describe 'fails for non-existing application', :as_cassette do
      before { get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/logs", request_headers }
      include_examples 'an unknown requested resource'
    end
  end
end

shared_examples 'valid:logs:download' do
  describe 'log download succeeds' do
    describe 'for type request as .log', :as_cassette do
      before do
        # TODO: at the time of writing this test, we assume that each platform provides a request log.
        # If this should not be the case, replace the request log with the first element in a queried log list
        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/request", request_headers
        @show_response = response
        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/request/download?file_format=log",
            request_headers
        @download_response = response
      end
      include_examples 'a valid GET request'
      it 'has a file attachment' do
        expect(@download_response.headers.keys).to include('Content-Disposition')
        expect(@download_response.headers['Content-Disposition']).to include('attachment;')
      end
      it 'binary body content is not empty' do
        expect(@download_response.headers.keys).to include('Content-Length')
        expect(@download_response.headers['Content-Length'].to_i).to be > 0
      end
      it 'attachment log content equals log content of the show request' do
        expect(@download_response.body).to eq(@show_response.body)
      end
    end

    describe 'for type request log as .zip', :as_cassette do
      before do
        # TODO: at the time of writing this test, we assume that each platform provides a request log.
        # If this should not be the case, replace the request log with the first element in a queried log list
        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/request", request_headers
        @show_response = response
        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/request/download?file_format=zip",
            request_headers
        @download_response = response
      end
      include_examples 'a valid GET request'
      it 'has a file attachment' do
        expect(@download_response.headers.keys).to include('Content-Disposition')
        expect(@download_response.headers['Content-Disposition']).to include('attachment;')
      end
      it 'binary body content is not empty' do
        expect(@download_response.headers.keys).to include('Content-Length')
        expect(@download_response.headers['Content-Length'].to_i).to be > 0
      end
      it 'content type is zip archive' do
        expect(@download_response.headers.keys).to include('Content-Type')
        expect(@download_response.headers['Content-Type']).to eql('application/zip')
      end
      it 'unzipped content equals log content of the show request' do
        downlaod_md5 = response_files_md5(@download_response.body, 'zip', false)
        show_md5 = Digest::MD5.hexdigest(@show_response.body)
        expect(downlaod_md5.values[0]).to eq(show_md5)
      end
    end

    describe 'for type request log as .tar.gz', :as_cassette do
      before do
        # TODO: at the time of writing this test, we assume that each platform provides a request log.
        # If this should not be the case, replace the request log with the first element in a queried log list
        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/request", request_headers
        @show_response = response
        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/request/download?file_format=tar.gz",
            request_headers
        @download_response = response
      end
      include_examples 'a valid GET request'
      it 'has a file attachment' do
        expect(@download_response.headers.keys).to include('Content-Disposition')
        expect(@download_response.headers['Content-Disposition']).to include('attachment;')
      end
      it 'binary body content is not empty' do
        expect(@download_response.headers.keys).to include('Content-Length')
        expect(@download_response.headers['Content-Length'].to_i).to be > 0
      end
      it 'content type is zip archive' do
        expect(@download_response.headers.keys).to include('Content-Type')
        expect(@download_response.headers['Content-Type']).to eql('application/gzip')
      end
      it 'unzipped content equals log content of the show request' do
        downlaod_md5 = response_files_md5(@download_response.body, 'tar.gz', false)
        show_md5 = Digest::MD5.hexdigest(@show_response.body)
        expect(downlaod_md5.values[0]).to eq(show_md5)
      end
    end
  end

  describe 'log download fails' do
    describe 'with non-existing application', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/logs/request/download", request_headers
      end
      include_examples 'an unknown requested resource'
    end

    describe 'with non-existing log', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/logs/request-xxxx/download",
            request_headers
      end
      include_examples 'an unknown requested resource'
    end

    describe 'with invalid file_format .rar', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/request/download?file_format=rar",
            request_headers
      end
      include_examples 'a bad request'
    end
  end
end

shared_examples 'valid:logs:download:all' do
  # TODO: download all log files, non-empty archive after deployment (!) --> test both download formats
  describe 'log download of all logs succeeds' do
    describe 'as .zip', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs", request_headers
        @log_list_response = response

        @shown_responses = {}
        # now grab each log as show response
        json_body[:logs].each do |log|
          get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/#{log[:id]}", request_headers
          @shown_responses[log[:id]] = response
        end

        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/download?archive_format=zip",
            request_headers
        @download_response = response
      end
      include_examples 'a valid GET request'
      it 'has a file attachment' do
        expect(@download_response).not_to be_nil
        expect(@download_response.headers.keys).to include('Content-Disposition')
        expect(@download_response.headers['Content-Disposition']).to include('attachment;')
      end
      it 'binary body content is not empty' do
        expect(@download_response).not_to be_nil
        expect(@download_response.headers.keys).to include('Content-Length')
        expect(@download_response.headers['Content-Length'].to_i).to be > 0
      end
      it 'content type is zip archive' do
        expect(@download_response).not_to be_nil
        expect(@download_response.headers.keys).to include('Content-Type')
        expect(@download_response.headers['Content-Type']).to eql('application/zip')
      end
      it 'unzipped content equals log content of the show requests' do
        expect(@download_response).not_to be_nil

        shown_md5 = {}
        @shown_responses.each do |id, shown_log|
          shown_md5[id] = Digest::MD5.hexdigest(shown_log.body)
        end
        downlaod_md5 = response_files_md5(@download_response.body, 'zip', false)

        # must contain at max the number of shown logs, empty log files will not be included in the download
        expect(downlaod_md5.length).to be <= shown_md5.length

        # now compare file hashes
        downlaod_md5.each do |_key, value|
          expect(shown_md5.values).to include(value)
        end
      end
    end

    describe 'as .tar.gz', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs", request_headers
        @log_list_response = response

        @shown_responses = {}
        # now grab each log as show response
        json_body[:logs].each do |log|
          get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/#{log[:id]}", request_headers
          @shown_responses[log[:id]] = response
        end

        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/download?archive_format=tar.gz",
            request_headers
        @download_response = response
      end
      include_examples 'a valid GET request'
      it 'has a file attachment' do
        expect(@download_response.headers.keys).to include('Content-Disposition')
        expect(@download_response.headers['Content-Disposition']).to include('attachment;')
      end
      it 'binary body content is not empty' do
        expect(@download_response.headers.keys).to include('Content-Length')
        expect(@download_response.headers['Content-Length'].to_i).to be > 0
      end
      it 'content type is zip archive' do
        expect(@download_response.headers.keys).to include('Content-Type')
        expect(@download_response.headers['Content-Type']).to eql('application/gzip')
      end
      it 'unzipped content equals log content of the show requests' do
        expect(@download_response).not_to be_nil

        shown_md5 = {}
        @shown_responses.each do |id, shown_log|
          shown_md5[id] = Digest::MD5.hexdigest(shown_log.body)
        end
        downlaod_md5 = response_files_md5(@download_response.body, 'tar.gz', false)

        # must contain at max the number of shown logs, empty log files will not be included in the download
        expect(downlaod_md5.length).to be <= shown_md5.length

        # now compare file hashes
        downlaod_md5.each do |_key, value|
          expect(shown_md5.values).to include(value)
        end
      end
    end
  end

  describe 'log download of all logs fails' do
    describe 'with invalid archive_format .rar', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/download?archive_format=rar",
            request_headers
      end
      include_examples 'a bad request'
    end
    describe 'with invalid archive_format .log', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/download?archive_format=rar",
            request_headers
      end
      include_examples 'a bad request'
    end
    describe 'with non-existing application', :as_cassette do
      before { get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/logs/download", request_headers }
      include_examples 'an unknown requested resource'
    end
  end
end

# shall be retrieved before application deployment so that the request log is actually empty
shared_examples 'valid:logs:get:empty' do
  describe 'log get empty of type request', :as_cassette do
    before do
      # TODO: at the time of writing this test, we assume that each platform provides a request log.
      # If this should not be the case, replace the request log with the first element in a queried log list
      get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/request", request_headers
    end
    include_examples 'a valid GET request'
    include_examples 'a valid log encoding'
    it 'does not contain any log messages' do
      expect(body.chomp.strip).to eq('')
    end
  end
end

# shall be retrieved after application deployment so that the request log contains entries
shared_examples 'valid:logs:get' do
  describe 'log get of type request', :as_cassette do
    before do
      # TODO: at the time of writing this test, we assume that each platform provides a request log.
      # If this should not be the case, replace the request log with the first element in a queried log list
      get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/request", request_headers
    end
    include_examples 'a valid GET request'
    include_examples 'a valid log encoding'
    it 'does contain at least one log message' do
      entries = body.split("\n")
      non_null_entries = entries.collect { |entry| entry if entry.chomp.strip != '' }.compact
      expect(non_null_entries.length).to be > 0
    end
  end

  describe 'log get fails' do
    describe 'with non-existent log_id', :as_cassette do
      before { get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/unknown_id", request_headers }
      include_examples 'an unknown requested resource'
    end

    describe 'with non-existing application', :as_cassette do
      before { get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/logs/request", request_headers }
      include_examples 'an unknown requested resource'
    end
  end
end

shared_examples 'valid:logs:tail' do
  describe 'log tail request', :as_cassette, :mock_websocket_on_replay do
    # all tests must be merged into one test, otherwise
    before do
      # TODO: at the time of writing this test, we assume that each platform provides a request log.
      # If this should not be the case, replace the request log with the first element in a queried log list

      get("/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}", request_headers)
      @app = json_body.dup
      # should not be empty due to previous web_url access
      get("/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/request", request_headers)
      @recent = body.dup

      # invoke URL request after x seconds, so that the tailing actually receives new messages
      EM.add_timer(3) do
        live_app = Excon.get(@app[:web_url])
        expect(live_app.status).to eql(200)
      end

      # TODO: use stream capable client to get rid of auto-close via the timeout in env['async.callback.auto.timeout']
      get("/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/request/tail", request_headers)
    end

    include_examples 'a valid GET request'
    include_examples 'a valid log encoding'

    it 'is a chunked response message' do
      expect(headers.keys).to include('Transfer-Encoding')
      expect(headers['Transfer-Encoding']).to eql('chunked')
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

  describe 'log tail fails' do
    describe 'with non-existent log_id', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/logs/unknown_id/tail", request_headers
      end
      include_examples 'an unknown requested resource'
    end

    describe 'with non-existing application', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/logs/request/tail", request_headers
      end
      include_examples 'an unknown requested resource'
    end
  end
end
