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

shared_examples 'valid:applications:create' do
  describe 'create application', cassette_group: 'application;create' do
    describe 'succeeds' do
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

    describe 'fails' do
      describe 'in 2nd attempt with duplicate name', :as_cassette do
        before do
          # repeat create with minimal properties
          application = { application: { name: @app_min[:original_name], runtimes: ['nodejs'] } }
          post "/endpoints/#{@endpoint}/applications", application, request_headers
        end
        include_examples 'a semantically invalid request'
      end
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
              application: { name: 'paasaltestcreateinvalidregion', runtimes: ['nodejs'], region: 'anyinvalidregion' }
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
  end
end

shared_examples 'valid:applications:get' do
  describe 'get application', cassette_group: 'application;get' do
    describe 'fails for non-existent application', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789", request_headers
      end
      include_examples 'an unknown requested resource'
    end
    describe 'succeeds', :as_cassette do
      # get previously created application
      before { get "/endpoints/#{@endpoint}/applications/#{@app_min[:original_name]}", request_headers }
      include_examples 'a valid GET request'
      include_examples 'application entity schema'
    end
  end
end

shared_examples 'valid:applications:list' do
  describe 'list applications', :as_cassette, cassette_group: 'application;list' do
    before { get "/endpoints/#{@endpoint}/applications", request_headers }
    include_examples 'a valid GET request'
    include_examples 'application list schema'
  end
end

shared_examples 'valid:applications:update' do
  describe 'application update', cassette_group: 'application;update' do
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

shared_examples 'valid:app:wordfinder' do
  it 'request has status 200' do
    expect(@live_app.status).to eql(200)
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
  describe 'web url access is possible', cassette_group: 'application;web access' do
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
  describe 'delete', cassette_group: 'application;delete' do
    describe 'succeeds for' do
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

    describe 'fails for non-existing application', :as_cassette do
      before do
        delete "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789", request_headers
      end
      include_examples 'an unknown requested resource'
    end
  end
end
