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
      get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789", request_headers
    end
    include_examples 'an unknown requested resource'
  end
end

shared_examples 'valid:applications:create' do
  describe 'create application fails' do
    describe 'with missing' do
      describe 'name property', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications", { application: { runtimes: ['ruby'] } }, request_headers
        end
        include_examples 'a bad request'
      end
      describe 'runtimes property', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications",
               { application: { name: 'paasaltestcreatewithmissingruntimes' } }, request_headers
        end
        include_examples 'a bad request'
      end
    end
    describe 'with invalid' do
      describe 'region', :as_cassette do
        before do
          application = {
            application: { name: 'paasaltestcreateinvalidregion', runtimes: [], region: 'anyinvalidregion' }
          }
          post "/endpoints/#{@endpoint}/applications", application, request_headers
        end
        include_examples 'a semantically invalid request'
        it 'bad request refers to invalid region' do
          expect(json_body[:dev_message]).to include('anyinvalidregion')
        end
      end
      describe 'runtimes' do
        describe 'by bad URL and unknown name', :as_cassette do
          before do
            application = {
              application: { name: 'paasaltestcreatebadruntimename', runtimes: ['youdontknowmert'] }
            }
            post "/endpoints/#{@endpoint}/applications", application, request_headers
          end
          include_examples 'a semantically invalid request'
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
            name: @app_all[:original_name], runtimes: ['nodejs'],
            region: @app_all[:region], autoscaled: false
          }
        }
        application[:application][:vendor_specific] = @application_params if @application_params
        post "/endpoints/#{@endpoint}/applications", application, request_headers
      end
      include_examples 'a valid POST request'
      include_examples 'application entity schema'
      include_examples 'application state: created'
    end

    describe 'of type nodejs with minimal properties', :as_cassette do
      before do
        application = { application: { name: @app_min[:original_name], runtimes: ['nodejs'] } }
        application[:application][:vendor_specific] = @application_params if @application_params
        post "/endpoints/#{@endpoint}/applications", application, request_headers
      end
      include_examples 'a valid POST request'
      include_examples 'application entity schema'
      include_examples 'application state: created'
    end
  end
end

shared_examples 'valid:applications:create:422' do
  describe 'create application (repeated) fails with duplicate name', :as_cassette do
    before do
      # repeat create with minimal properties
      application = { application: { name: @app_min[:original_name], runtimes: ['nodejs'] } }
      post "/endpoints/#{@endpoint}/applications", application, request_headers
    end
    include_examples 'a semantically invalid request'
  end
end

shared_examples 'valid:applications:get' do
  describe 'get application', :as_cassette do
    # get previously created application
    before { get "/endpoints/#{@endpoint}/applications/#{@app_min[:original_name]}", request_headers }
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
  describe 'application update' do
    describe 'succeeds when' do
      describe 'changing only the name', :as_cassette do
        before do
          application = { application: { name: @app_all[:updated_name] } }
          patch "/endpoints/#{@endpoint}/applications/#{@app_all[:original_name]}", application, request_headers
        end
        include_examples 'a valid PATCH request'
        it 'name change reflected in response' do
          expect(json_body[:name]).to eql @app_all[:updated_name]
        end
      end

      describe 'changing only the runtimes', :as_cassette do
        before do
          application = { application: { runtimes: ['ruby'] } }
          patch "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}", application, request_headers
        end
        include_examples 'a valid PATCH request'
        it 'name unchanged in response' do
          expect(json_body[:name]).to eql @app_all[:updated_name]
        end
      end

      describe 'changing name and runtimes', :as_cassette do
        before do
          application = { application: { name: @app_min[:updated_name], runtimes: ['java'] } }
          patch "/endpoints/#{@endpoint}/applications/#{@app_min[:original_name]}", application, request_headers
        end
        include_examples 'a valid PATCH request'
        it 'name change reflected in response' do
          expect(json_body[:name]).to eql @app_min[:updated_name]
        end
      end

      describe 'reverting runtime change for app with min properties', :as_cassette do
        before do
          application = { application: { runtimes: ['nodejs'] } }
          patch "/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}", application, request_headers
        end
        include_examples 'a valid PATCH request'
        it 'name unchanged in response' do
          expect(json_body[:name]).to eql @app_min[:updated_name]
        end
      end

      describe 'reverting runtime change for app with all properties', :as_cassette do
        before do
          application = { application: { runtimes: ['nodejs'] } }
          patch "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}", application, request_headers
        end
        include_examples 'a valid PATCH request'
        it 'name unchanged in response' do
          expect(json_body[:name]).to eql @app_all[:updated_name]
        end
      end
    end
    describe 'fails for non-existing application', :as_cassette do
      before do
        application = { application: { name: 'renamednonexistingapp', runtimes: ['ruby'] } }
        patch "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789", application, request_headers
      end
      include_examples 'an unknown requested resource'
    end
  end
end

shared_examples 'valid:applications:data:download:422' do
  describe 'data download of type tar.gz fails when there is no deployment', :as_cassette do
    before do
      get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/data/download?archive_format=tar.gz",
          request_headers
    end
    include_examples 'a semantically invalid request'
  end
  describe 'data download with default type fails when there is no deployment', :as_cassette do
    before { get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/data/download", request_headers }
    include_examples 'a semantically invalid request'
  end
end

shared_examples 'valid:applications:data:deploy' do
  describe 'deployment' do
    describe 'fails for' do
      describe 'unsupported archive compression of type .tbz2', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/data/deploy",
               { file: Rack::Test::UploadedFile.new('spec/adapter/application-archives/valid-sample-app.tbz2',
                                                    'application/x-gtar') },
               request_headers
        end
        include_examples 'a bad request'
      end
      describe 'unsupported archive compression of type .tbz2 but with supported mime type',
               :as_cassette, :mock_fs_on_replay do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/data/deploy",
               { file: Rack::Test::UploadedFile.new('spec/adapter/application-archives/valid-sample-app.tbz2',
                                                    'application/gzip') },
               request_headers
        end
        include_examples 'a bad request'
      end
      describe 'corrupted .zip archive', :as_cassette, :mock_fs_on_replay do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/data/deploy",
               { file: Rack::Test::UploadedFile.new('spec/adapter/application-archives/corrupted-archive.zip',
                                                    'application/zip') },
               request_headers
        end
        include_examples 'a bad request'
      end
      describe 'corrupted .tar.gz archive', :as_cassette, :mock_fs_on_replay do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/data/deploy",
               { file: Rack::Test::UploadedFile.new('spec/adapter/application-archives/corrupted-archive.tar.gz',
                                                    'application/gzip') },
               request_headers
        end
        include_examples 'a bad request'
      end
    end

    describe 'succeeds', :mock_fs_on_replay do
      describe 'with valid .zip application archive', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/data/deploy",
               { file: Rack::Test::UploadedFile.new('spec/adapter/application-archives/valid-sample-app.zip',
                                                    'application/zip') }, request_headers
        end
        include_examples 'contains the request ID'
        it 'has status 204' do
          expect_status 204
        end
      end
      describe 'and subsequent GET application with all properties shows that', :as_cassette do
        it 'state changes to deployed within timeout period' do
          wait(10.seconds).for do
            get("/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}", request_headers)[:state]
          end.to eq('deployed')
        end
      end

      describe 'with valid .tar.gz application archive', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}/data/deploy",
               { file: Rack::Test::UploadedFile.new('spec/adapter/application-archives/valid-sample-app.tar.gz',
                                                    'application/gzip') }, request_headers
        end
        include_examples 'contains the request ID'
        it 'has status 204' do
          expect_status 204
        end
      end
      describe 'and subsequent GET application with min properties shows that', :as_cassette do
        it 'state changes to deployed within timeout period' do
          wait(10.seconds).for do
            get("/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}", request_headers)[:state]
          end.to eq('deployed')
        end
      end
    end
  end
end

shared_examples 'valid:applications:data:rebuild:422' do
  describe 'rebuild data fails when there is no deployment', :as_cassette do
    before do
      post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/data/rebuild", {}, request_headers
    end
    include_examples 'a semantically invalid request'
  end
end

shared_examples 'valid:applications:data:rebuild' do
  describe 'deployment data rebuild', :mock_fs_on_replay do
    describe 'succeeds', :as_cassette do
      before do
        post "/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}/data/rebuild", {}, request_headers
      end
      include_examples 'a valid POST request'
      include_examples 'application entity schema'
    end

    describe 'changes the release_version property', :as_cassette do
      it 'changes the application state' do
        app_before_rebuild = get("/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}", request_headers)
        post("/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/data/rebuild", {}, request_headers)
        wait(20.seconds).for do
          get("/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}", request_headers)[:release_version]
        end.not_to eq(app_before_rebuild[:release_version])
      end
    end
  end
end

shared_examples 'valid:applications:data:download' do
  describe 'deployment data download' do
    describe 'succeeds', :mock_fs_on_replay do
      describe 'for default archive_format .zip', :as_cassette do
        before { get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/data/download", request_headers }
        include_examples 'a valid GET request'
        it 'has a file attachment' do
          expect(headers.keys).to include('Content-Disposition')
          expect(headers['Content-Disposition']).to include('attachment;')
        end
        it 'content type is zip archive' do
          expect(headers.keys).to include('Content-Type')
          expect(headers['Content-Type']).to eql('application/zip')
        end
        it 'binary body content is not empty' do
          expect(headers.keys).to include('Content-Length')
          expect(headers['Content-Length'].to_i).to be > 0
        end
        it 'contents are identical to the deployed zip archive' do
          # archives won't be equal due to different zip compression, etc., but files should be identical
          deployed_md5 = deployed_files_md5('spec/adapter/application-archives/valid-sample-app.zip', 'zip')
          downlaod_md5 = response_files_md5(body, 'zip')

          # must contain at least all deployed files
          expect(downlaod_md5.length).to be >= deployed_md5.length

          # now compare file hashes
          deployed_md5.each do |key, value|
            expect(downlaod_md5[key]).to_not be_nil
            expect(downlaod_md5[key]).to eql(value)
          end
        end
      end

      describe 'for archive_format .tar.gz', :as_cassette do
        before do
          get "/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}/data/download?archive_format=tar.gz",
              request_headers
        end
        include_examples 'a valid GET request'
        it 'has a file attachment' do
          expect(headers.keys).to include('Content-Disposition')
          expect(headers['Content-Disposition']).to include('attachment;')
        end
        it 'content type is tar.gz archive' do
          expect(headers.keys).to include('Content-Type')
          expect(headers['Content-Type']).to eql('application/gzip')
        end
        it 'binary body content is not empty' do
          expect(headers.keys).to include('Content-Length')
          expect(headers['Content-Length'].to_i).to be > 0
        end
        it 'contents are identical to the deployed tar.gz archive' do
          # archives won't be equal due to different zip compression, etc., but files should be identical
          deployed_md5 = deployed_files_md5('spec/adapter/application-archives/valid-sample-app.tar.gz', 'tar.gz')
          downlaod_md5 = response_files_md5(body, 'tar.gz')

          # must contain at least all deployed files
          expect(downlaod_md5.length).to be >= deployed_md5.length

          # now compare file hashes
          deployed_md5.each do |key, value|
            expect(downlaod_md5[key]).to_not be_nil
            expect(downlaod_md5[key]).to eql(value)
          end
        end
      end
    end

    describe 'fails' do
      describe 'with invalid archive_format .rar', :as_cassette do
        before do
          get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/data/download?archive_format=rar",
              request_headers
        end
        include_examples 'a bad request'
      end

      describe 'for non-existing application', :as_cassette do
        before { get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/data/download", request_headers }
        include_examples 'an unknown requested resource'
      end
    end
  end
end

shared_examples 'valid:app:wordfinder' do
  it 'request has status 200' do
    @live_app.status = 200
  end
  it 'is the wordfinder application title' do
    expect(@live_app.body).to include('<title>Word Finder</title>')
  end
  it 'is the wordfinder application body' do
    expect(@live_app.body).to include('I took every english word (over 200k words) and built a little app '\
          'that will help you find words that contain specific characters')
  end
end

shared_examples 'valid:applications:web' do
  describe 'application can be accessed at its web url' do
    describe 'for app with all properties', :as_cassette do
      before do
        app = get("/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}", request_headers)
        # use excon so that the external request is recorded
        @live_app = Excon.get(app[:web_url])
      end
      include_examples 'valid:app:wordfinder'
    end

    describe 'for app with min properties', :as_cassette do
      before do
        app = get("/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}", request_headers)
        # CF Hack, sometimes this app requires more time before the route is ready
        wait(5.seconds).for { Excon.get(app[:web_url]).body }.not_to include('404 Not Found: Requested route')
        # use excon so that the external request is recorded
        @live_app = Excon.get(app[:web_url])
      end
      include_examples 'valid:app:wordfinder'
    end
  end
end

shared_examples 'valid:applications:delete' do
  describe 'delete succeeds for' do
    describe 'previously created application' do
      describe 'with min properties', :as_cassette do
        before do
          delete "/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}", request_headers
        end
        include_examples 'a valid DELETE request'
      end
      describe 'makes subsequent GET of application with min properties invalid', :as_cassette do
        before { get "/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}", request_headers }
        include_examples 'an unknown requested resource'
      end

      describe 'with all properties', :as_cassette do
        before do
          delete "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}", request_headers
        end
        include_examples 'a valid DELETE request'
      end
      describe 'makes subsequent GET of application with all properties invalid', :as_cassette do
        before { get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}", request_headers }
        include_examples 'an unknown requested resource'
      end
    end
  end

  describe 'delete fails for non-existing application', :as_cassette do
    before do
      delete "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789", request_headers
    end
    include_examples 'an unknown requested resource'
  end
end
