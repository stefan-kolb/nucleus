# NOTE: use only 'paasal-test-app-all-updated' as valid app throughout all tests

shared_examples 'env_var list schema' do
  it 'complies with the env_var list schema' do
    expect_json_keys(Paasal::API::Models::EnvironmentVariables.documentation.keys)
  end
end

shared_examples 'env_var entity schema' do
  it 'complies with the env_var entity schema' do
    expect_json_keys(Paasal::API::Models::EnvironmentVariable.documentation.keys)
  end
end

shared_examples 'valid:vars:list:empty' do
  describe 'list empty env_vars', :as_cassette do
    before { get "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars", request_headers }
    include_examples 'a valid GET request'
    include_examples 'env_var list schema'
    it 'does not contain any env vars' do
      expect(json_body[:env_vars]).to eql([])
    end
  end

  describe 'list empty env_vars fails for non-existing application', :as_cassette do
    before { get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/vars", request_headers }
    include_examples 'an unknown requested resource'
  end
end

shared_examples 'valid:vars:list' do
  describe 'list env_vars', :as_cassette do
    before { get "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars", request_headers }
    include_examples 'a valid GET request'
    include_examples 'env_var list schema'
    it 'does contain some env vars' do
      expect(json_body[:env_vars]).not_to eql([])
    end
  end

  describe 'list env_vars fails for non-existing application', :as_cassette do
    before { get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/vars", request_headers }
    include_examples 'an unknown requested resource'
  end
end

shared_examples 'valid:vars:create:400' do
  describe 'create env_var fails' do
    describe 'with missing key property', :as_cassette do
      before do
        post "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars",
             { variable: { value: 'our_test_var_value' } }, request_headers
      end
      include_examples 'a bad request'
      it 'bad request refers to missing key' do
        expect(json_body[:dev_message]).to include('[key] is missing')
      end
    end
    describe 'with missing value property', :as_cassette do
      before do
        post "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars",
             { variable: { key: 'our_test_var_key' } }, request_headers
      end
      include_examples 'a bad request'
      it 'bad request refers to missing value' do
        expect(json_body[:dev_message]).to include('[value] is missing')
      end
    end
    # TODO: do we have any invalid / restricted properties?
  end
end

shared_examples 'valid:vars:create' do
  describe 'create env_var using app with all properties', :as_cassette do
    before do
      post "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars",
           { variable: { key: 'our_test_var_key', value: 'our_test_var_value' } }, request_headers
    end
    include_examples 'a valid POST request'
    include_examples 'env_var entity schema'
    it 'has valid value property' do
      expect(json_body[:value]).to eql('our_test_var_value')
    end
    it 'has valid key property' do
      expect(json_body[:key]).to eql('our_test_var_key')
    end
  end

  describe 'create 2nd env_var using app with all properties' do
    describe 'succeeds', :as_cassette do
      before do
        post "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars",
             { variable: { key: 'our_test_var_key2', value: 'our_test_var_value2' } }, request_headers
      end
      include_examples 'a valid POST request'
      include_examples 'env_var entity schema'
      it 'has valid value property' do
        expect(json_body[:value]).to eql('our_test_var_value2')
      end
      it 'has valid key property' do
        expect(json_body[:key]).to eql('our_test_var_key2')
      end
    end
    describe 'did not alter other vars', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars", request_headers
      end
      include_examples 'a valid GET request'
      include_examples 'env_var list schema'
      it 'has 2 vars' do
        expect(json_body[:env_vars].length).to eql(2)
      end
      it 'other var kept its value' do
        first_var = json_body[:env_vars].find { |var| var[:id] == 'our_test_var_key' }
        expect(first_var).to_not be_nil
        expect(first_var[:value]).to eql('our_test_var_value')
      end
    end
  end

  describe 'create env_var using app with min properties', :as_cassette do
    before do
      post "/endpoints/#{@endpoint}/applications/paasal-test-app-min-updated/vars",
           { variable: { key: 'our_test_var_key', value: 'our_test_var_value' } }, request_headers
    end
    include_examples 'a valid POST request'
    include_examples 'env_var entity schema'
    it 'has valid value property' do
      expect(json_body[:value]).to eql('our_test_var_value')
    end
    it 'has valid key property' do
      expect(json_body[:key]).to eql('our_test_var_key')
    end
  end
end

shared_examples 'valid:vars:create:422' do
  describe 'create env_var fails' do
    describe 'if the key is already used', :as_cassette do
      before do
        post "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars",
             { variable: { key: 'our_test_var_key', value: 'our_test_var_value_duplicate' } }, request_headers
      end
      include_examples 'a semantically invalid request'
      it 'bad request refers to already taken key' do
        expect(json_body[:dev_message]).to include('already taken')
      end
    end
  end
end

shared_examples 'valid:vars:update:400' do
  describe 'update env_var fails with missing value property', :as_cassette do
    before do
      patch "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars/our_test_var_key",
            { variable: {} }, request_headers
    end
    include_examples 'a bad request'
    it 'bad request refers to missing value' do
      expect(json_body[:dev_message]).to include('[value] is missing')
    end
  end
end

shared_examples 'valid:vars:update' do
  describe 'update env_var' do
    describe 'succeeds', :as_cassette do
      before do
        patch "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars/our_test_var_key",
              { variable: { value: 'our_updated_test_var_value' } }, request_headers
      end
      include_examples 'a valid PATCH request'
      include_examples 'env_var entity schema'
      it 'has valid value property' do
        expect(json_body[:value]).to eql('our_updated_test_var_value')
      end
      it 'has valid key property' do
        expect(json_body[:key]).to eql('our_test_var_key')
      end
    end
    describe 'did not alter other vars', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars", request_headers
      end
      include_examples 'a valid GET request'
      include_examples 'env_var list schema'
      it 'has 2 vars' do
        expect(json_body[:env_vars].length).to eql(2)
      end
      it 'other var kept its value' do
        first_var = json_body[:env_vars].find { |var| var[:id] == 'our_test_var_key2' }
        expect(first_var).to_not be_nil
        expect(first_var[:value]).to eql('our_test_var_value2')
      end
    end
  end
end

shared_examples 'valid:vars:update:404' do
  describe 'update env_var fails with non-existing key', :as_cassette do
    before do
      patch "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars/non_existing_key",
            { variable: { value: 'our_test_var_value_updated' } }, request_headers
    end
    include_examples 'an unknown requested resource'
    it 'bad request refers to invalid key' do
      expect(json_body[:dev_message]).to include('non_existing_key')
    end
  end
end

shared_examples 'valid:vars:get:404' do
  describe 'get env_var fails for non-existent key', :as_cassette do
    before { get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/vars/unknown_key", request_headers }
    include_examples 'an unknown requested resource'
  end
end

shared_examples 'valid:vars:get' do
  describe 'get env_var', :as_cassette do
    before do
      get "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars/our_test_var_key", request_headers
    end
    include_examples 'a valid GET request'
    include_examples 'env_var entity schema'
    it 'has valid value property' do
      expect(json_body[:value]).to eql('our_updated_test_var_value')
    end
    it 'has valid key property' do
      expect(json_body[:key]).to eql('our_test_var_key')
    end
  end
end

shared_examples 'valid:vars:delete' do
  describe 'delete env_var' do
    describe 'succeeds', :as_cassette do
      before do
        delete "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars/our_test_var_key", request_headers
      end
      include_examples 'a valid DELETE request'
    end
    describe 'did not alter other vars', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars", request_headers
      end
      include_examples 'a valid GET request'
      include_examples 'env_var list schema'
      it 'has 1 vars' do
        expect(json_body[:env_vars].length).to eql(1)
      end
      it 'other var kept its value' do
        first_var = json_body[:env_vars].find { |var| var[:id] == 'our_test_var_key2' }
        expect(first_var).to_not be_nil
        expect(first_var[:value]).to eql('our_test_var_value2')
      end
    end
  end

  describe 'delete env_var fails for' do
    describe 'non-existing key', :as_cassette do
      before do
        delete "/endpoints/#{@endpoint}/applications/paasal-test-app-all-updated/vars/unknown_key", request_headers
      end
      include_examples 'an unknown requested resource'
    end

    describe 'non-existing application', :as_cassette do
      before do
        delete "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/vars/our_test_var_key", request_headers
      end
      include_examples 'an unknown requested resource'
    end
  end
end
