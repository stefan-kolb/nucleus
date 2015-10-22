shared_examples 'valid:auth_client' do
  describe '#auth_client', :as_cassette do
    before do
      @auth_client = @adapter.auth_client
    end

    it 'does not return nil' do
      expect(@auth_client).to_not be_nil
    end
    it 'does return an AuthClient instance' do
      expect(@auth_client).to be_a Nucleus::Adapters::AuthClient
    end
    it 'is not immediately authenticated' do
      expect { @auth_client.auth_header }.to raise_error(Nucleus::Errors::EndpointAuthenticationError)
    end
  end
end
