shared_examples 'compliant adapter with invalid credentials' do
  # tests all existing routes behind the application (according to swagger)
  describe 'is compliant and' do
    # get the swagger schema that includes all application endpoints
    browser = Rack::Test::Session.new(Rack::MockSession.new(Airborne.configuration.rack_app))
    browser.send('get', '/schema', {}, {})
    operations = Oj.load(browser.last_response.body, symbol_keys: true)[:paths].collect do |key, value|
      next unless key.to_s.include?('/endpoints/{endpoint_id}/')

      { path: key.to_s, methods: value.collect { |k, _v| k.to_s } }
    end.compact.flatten

    # operations must not be empty
    it 'has application operations' do
      expect(operations).not_to be_empty
    end

    operations.each do |operation|
      operation[:methods].each do |method|
        describe "#{method}: #{operation[:path]}" do
          before do
            # substitute random IDs for the request query params
            operation[:path].gsub!(/\{endpoint_id}/, @endpoint)
            # substitute random IDs for the request query params
            operation[:path].gsub!(/\{.*?\}/, SecureRandom.uuid)
            # substitude native call path
            operation[:path].gsub!(/\*path/, 'some/native/path')
            # execute the request that shall fail with 401
            # TODO: only get requests?
            get operation[:path], request_headers
          end
          include_examples 'an unauthorized request'
        end
      end
    end
  end
end
