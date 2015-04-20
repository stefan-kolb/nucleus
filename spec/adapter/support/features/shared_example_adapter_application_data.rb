shared_examples 'valid:applications:data:download:422' do
  describe 'deployment data download', cassette_group: 'application-data;download' do
    describe 'of type tar.gz fails when there is no deployment', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/data/download?archive_format=tar.gz",
            request_headers
      end
      include_examples 'a semantically invalid request'
    end
    describe 'with default type fails when there is no deployment', :as_cassette do
      before { get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/data/download", request_headers }
      include_examples 'a semantically invalid request'
    end
  end
end

shared_examples 'valid:applications:data:deploy' do
  describe 'deployment', cassette_group: 'application-data;deploy' do
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
          wait(60.seconds).for do
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
          wait(60.seconds).for do
            get("/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}", request_headers)[:state]
          end.to eq('deployed')
        end
      end
    end
  end
end

shared_examples 'valid:applications:data:rebuild:422' do
  describe 'deployment data rebuild', cassette_group: 'application-data;rebuild' do
    describe 'fails when there is no deployment', :as_cassette do
      before do
        post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/data/rebuild", {}, request_headers
      end
      include_examples 'a semantically invalid request'
    end
  end
end

shared_examples 'valid:applications:data:rebuild' do
  describe 'deployment data rebuild', :mock_fs_on_replay, cassette_group: 'application-data;rebuild' do
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
        wait(60.seconds).for do
          get("/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}", request_headers)[:release_version]
        end.not_to eq(app_before_rebuild[:release_version])
      end
    end
  end
end

shared_examples 'valid:applications:data:download' do
  describe 'deployment data download', cassette_group: 'application-data;download' do
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
