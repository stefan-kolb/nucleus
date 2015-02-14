shared_examples 'invalid: #authenticate' do
  describe '#authenticate' do
    it 'does throw unauthorized exception' do
      expect { @adapter.authenticate('invalid_username', 'invalid_password') }.to(
          raise_error Paasal::Errors::AuthenticationError)
    end
  end
end

shared_examples 'valid: #authenticate' do
  describe '#authenticate' do
    it 'returns an authentication header' do
      username, password = username_password(@endpoint)
      auth_header = @adapter.authenticate(username, password)
      expect(auth_header).to_not be_nil
      expect(auth_header).to be_a Hash
      expect(auth_header.keys[0]).to eql 'Authorization'
    end
  end
end

shared_examples 'invalid: list applications' do
  describe 'list applications' do
    before { get "/endpoints/#{@endpoint}/applications", request_headers }
    include_examples 'an unauthorized request'
  end
end

shared_examples 'valid: list applications' do
  describe 'list applications' do
    before { get "/endpoints/#{@endpoint}/applications", request_headers }
    include_examples 'a valid GET request'
    include_examples 'application list schema'
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

shared_examples 'domain list schema' do
  it 'complies with the domain list schema' do
    expect_json_keys(Paasal::API::Models::Domains.documentation.keys)
  end
end

shared_examples 'domain entity schema' do
  it 'complies with the domain entity schema' do
    expect_json_keys(Paasal::API::Models::Domain.documentation.keys)
  end
end

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
