shared_examples 'compliant adapter with invalid credentials' do
  # tests all existing routes behind the application (according to swagger)
  describe 'is compliant and' do
    # get the swagger schema that includes all application endpoints
    browser = Rack::Test::Session.new(Rack::MockSession.new(Airborne.configuration.rack_app))
    browser.send('get', '/schema/endpoints', {}, {})
    operations = Oj.load(browser.last_response.body, symbol_keys: true)[:apis].collect do |api|
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
