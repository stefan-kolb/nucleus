shared_examples 'valid:applications:lifecycle' do
  describe 'lifecycle operations', :mock_fs_on_replay, cassette_group: 'app-actions;lifecycle' do
    [:@app_all, :@app_min].each do |app_name|
      describe 'start' do
        describe "succeeds for #{app_name} if currently stopped", :as_cassette do
          before do
            post("/endpoints/#{@endpoint}/applications/#{instance_variable_get(app_name)[:updated_name]}/actions/start",
                 {}, request_headers)
          end
          it 'changes state to running within timeout period' do
            wait(40.seconds).for do
              get("/endpoints/#{@endpoint}/applications/#{instance_variable_get(app_name)[:updated_name]}",
                  request_headers)[:state]
            end.to eq('running')
          end
        end
        describe "succeeds for #{app_name} if already running", :as_cassette do
          before do
            post("/endpoints/#{@endpoint}/applications/#{instance_variable_get(app_name)[:updated_name]}/actions/start",
                 {}, request_headers)
          end
          it 'changes state to running within timeout period' do
            expect(get("/endpoints/#{@endpoint}/applications/#{instance_variable_get(app_name)[:updated_name]}",
                       request_headers)[:state]).to eql('running')
          end
        end
      end
      describe 'stop' do
        describe "succeeds for #{app_name} if currently running", :as_cassette do
          before do
            post("/endpoints/#{@endpoint}/applications/#{instance_variable_get(app_name)[:updated_name]}/actions/stop",
                 {}, request_headers)
          end
          it 'changes state to stopped within timeout period' do
            wait(20.seconds).for do
              get("/endpoints/#{@endpoint}/applications/#{instance_variable_get(app_name)[:updated_name]}",
                  request_headers)[:state]
            end.to eq('stopped')
          end
        end
        describe "succeeds for #{app_name} if already stopped", :as_cassette do
          before do
            post("/endpoints/#{@endpoint}/applications/#{instance_variable_get(app_name)[:updated_name]}/actions/stop",
                 {}, request_headers)
          end
          it 'changes state to stopped within timeout period' do
            expect(get("/endpoints/#{@endpoint}/applications/#{instance_variable_get(app_name)[:updated_name]}",
                       request_headers)[:state]).to eql('stopped')
          end
        end
      end
      describe 'restart' do
        describe "succeeds for #{app_name} if currently stopped", :as_cassette do
          before do
            post("/endpoints/#{@endpoint}/applications/#{instance_variable_get(app_name)[:updated_name]}/"\
              'actions/restart', {}, request_headers)
          end
          it 'changes state to running within timeout period' do
            wait(20.seconds).for do
              get("/endpoints/#{@endpoint}/applications/#{instance_variable_get(app_name)[:updated_name]}",
                  request_headers)[:state]
            end.to eq('running')
          end
        end
        describe "succeeds for #{app_name} if currently running", :as_cassette do
          before do
            post("/endpoints/#{@endpoint}/applications/#{instance_variable_get(app_name)[:updated_name]}/"\
              'actions/restart', {}, request_headers)
          end
          it 'changes state to running within timeout period' do
            wait(20.seconds).for do
              get("/endpoints/#{@endpoint}/applications/#{instance_variable_get(app_name)[:updated_name]}",
                  request_headers)[:state]
            end.to eq('running')
          end
        end
      end
    end
  end
end

shared_examples 'valid:applications:lifecycle:422' do
  describe 'lifecycle operations fail before deployment was made', :mock_fs_on_replay,
           cassette_group: 'app-actions;lifecycle;fail' do
    describe 'start' do
      describe 'fails', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/actions/start", {}, request_headers
        end
        include_examples 'a semantically invalid request'
      end
      describe 'subsq. req. shows no state changes', :as_cassette do
        before { get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}", request_headers }
        include_examples 'application state: created'
      end
    end
    describe 'stop' do
      describe 'fails', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/actions/stop", {}, request_headers
        end
        include_examples 'a semantically invalid request'
      end
      describe 'subsq. req. shows no state changes', :as_cassette do
        before { get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}", request_headers }
        include_examples 'application state: created'
      end
    end
    describe 'restart' do
      describe 'fails', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/actions/restart", {}, request_headers
        end
        include_examples 'a semantically invalid request'
      end
      describe 'subsq. req. shows no state changes', :as_cassette do
        before { get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}", request_headers }
        include_examples 'application state: created'
      end
    end
  end
end
