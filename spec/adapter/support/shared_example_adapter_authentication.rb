shared_examples 'invalid:#authenticate' do
  describe '#authenticate' do
    it 'does throw unauthorized exception' do
      expect { @adapter.authenticate('invalid_username', 'invalid_password') }.to(
        raise_error Paasal::Errors::AuthenticationError)
    end
  end
end

shared_examples 'valid:#authenticate' do
  describe '#authenticate' do
    before do
      username, password = username_password(@endpoint)
      @auth_header = @adapter.authenticate(username, password)
    end

    it 'does not return nil' do
      expect(@auth_header).to_not be_nil
    end
    it 'does return an hash' do
      expect(@auth_header).to be_a Hash
    end
    it 'does return an auth header' do
      expect(@auth_header.keys[0]).to eql 'Authorization'
    end
  end
end

shared_examples 'valid: OAuth2 #authenticate' do
  describe '#authenticate' do
    before do
      username, password = username_password(@endpoint)
      @auth_client = @adapter.authenticate(username, password)
    end

    it 'does not return nil' do
      expect(@auth_client).to_not be_nil
    end
    it 'does return an O2Auth instance' do
      expect(@auth_client).to be_a Paasal::OAuth2Client
    end
    it 'has access to an auth header' do
      expect(@auth_client.auth_header).to be_a Hash
    end
    it 'is authenticated' do
      expect(@auth_client.auth_header.keys[0]).to eql 'Authorization'
    end
  end
end
