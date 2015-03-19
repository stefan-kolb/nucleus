shared_examples 'valid:applications:lifecycle' do
  describe 'lifecycle operations' do
    %w(paasal-test-app-all-updated paasal-test-app-min-updated).each do |app_name|
      describe "start succeeds for #{app_name} if currently stopped", :as_cassette do
        before do
          post("/endpoints/#{@endpoint}/applications/#{app_name}/actions/start", {}, request_headers)
        end
        it 'changes state to running within timeout period' do
          wait(20.seconds).for do
            get("/endpoints/#{@endpoint}/applications/#{app_name}", request_headers)[:state]
          end.to eq('running')
        end
      end
      describe "start succeeds for #{app_name} if already running", :as_cassette do
        before do
          post("/endpoints/#{@endpoint}/applications/#{app_name}/actions/start", {}, request_headers)
        end
        it 'changes state to running within timeout period' do
          wait(20.seconds).for do
            get("/endpoints/#{@endpoint}/applications/#{app_name}", request_headers)[:state]
          end.to eq('running')
        end
      end
      describe "stop succeeds for #{app_name} if currently running", :as_cassette do
        before do
          post("/endpoints/#{@endpoint}/applications/#{app_name}/actions/stop", {}, request_headers)
        end
        it 'changes state to stopped within timeout period' do
          wait(20.seconds).for do
            get("/endpoints/#{@endpoint}/applications/#{app_name}", request_headers)[:state]
          end.to eq('stopped')
        end
      end
      describe "stop succeeds for #{app_name} if already stopped", :as_cassette do
        before do
          post("/endpoints/#{@endpoint}/applications/#{app_name}/actions/stop", {}, request_headers)
        end
        it 'changes state to stopped within timeout period' do
          wait(20.seconds).for do
            get("/endpoints/#{@endpoint}/applications/#{app_name}", request_headers)[:state]
          end.to eq('stopped')
        end
      end
      describe "restart succeeds for #{app_name} if currently stopped", :as_cassette do
        before do
          post("/endpoints/#{@endpoint}/applications/#{app_name}/actions/restart", {}, request_headers)
        end
        it 'changes state to running within timeout period' do
          wait(20.seconds).for do
            get("/endpoints/#{@endpoint}/applications/#{app_name}", request_headers)[:state]
          end.to eq('running')
        end
      end
      describe "restart succeeds for #{app_name} if currently running", :as_cassette do
        before do
          post("/endpoints/#{@endpoint}/applications/#{app_name}/actions/restart", {}, request_headers)
        end
        it 'changes state to running within timeout period' do
          wait(20.seconds).for do
            get("/endpoints/#{@endpoint}/applications/#{app_name}", request_headers)[:state]
          end.to eq('running')
        end
      end
    end
  end
end

shared_examples 'valid:applications:lifecycle:422' do
  describe 'lifecycle operations' do
    describe 'fail when there is no deployment' do
      describe 'start' do
        describe 'fails', :as_cassette do
          before do
            post "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/actions/start", {}, request_headers
          end
          include_examples 'a semantically invalid request'
        end
        describe 'subsequent GET application shows no state changes', :as_cassette do
          before { get "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated", request_headers }
          include_examples 'application state: created'
        end
      end
      describe 'stop' do
        describe 'fails', :as_cassette do
          before do
            post "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/actions/stop", {}, request_headers
          end
          include_examples 'a semantically invalid request'
        end
        describe 'subsequent GET application shows no state changes', :as_cassette do
          before { get "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated", request_headers }
          include_examples 'application state: created'
        end
      end
      describe 'restart' do
        describe 'fails', :as_cassette do
          before do
            post "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/actions/restart", {}, request_headers
          end
          include_examples 'a semantically invalid request'
        end
        describe 'subsequent GET application shows no state changes', :as_cassette do
          before { get "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated", request_headers }
          include_examples 'application state: created'
        end
      end
    end
  end
end
