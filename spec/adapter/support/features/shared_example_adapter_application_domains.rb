# NOTE: use only 'nucleus-test-app-all-updated' as valid app throughout all tests

shared_examples 'domain list schema' do
  it 'complies with the domain list schema' do
    expect_json_keys(Nucleus::API::Models::Domains.documentation.keys)
  end
end

shared_examples 'domain entity schema' do
  it 'complies with the domain entity schema' do
    expect_json_keys(Nucleus::API::Models::Domain.documentation.keys)
  end
end

shared_examples 'valid:applications:domains:list:empty' do
  describe 'domains list empty', :as_cassette, cassette_group: 'app-domains;list' do
    before { get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains", request_headers }
    include_examples 'a valid GET request'
    include_examples 'domain list schema'
    it 'does not contain any domain' do
      expect(json_body[:domains]).to eql([])
    end
  end
end

shared_examples 'valid:applications:domains:list' do
  describe 'domains list', cassette_group: 'app-domains;list' do
    describe 'succeeds', :as_cassette do
      before { get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains", request_headers }
      include_examples 'a valid GET request'
      include_examples 'domain list schema'
      it 'does contain 2 domains' do
        expect(json_body[:domains]).not_to eql([])
        expect(json_body[:domains].length).to eql(2)
      end
    end

    describe 'fails for non-existing application', :as_cassette do
      before { get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/domains", request_headers }
      include_examples 'an unknown requested resource'
    end
  end
end

shared_examples 'valid:applications:domains:create' do
  describe 'domains create', cassette_group: 'app-domains;create' do
    describe 'fails' do
      describe 'with invalid name' do
        describe 'name without TLD', :as_cassette do
          before do
            post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains",
                 { domain: { name: 'abcdefghijkl' } }, request_headers
          end
          include_examples 'a semantically invalid request'
        end
        describe 'email as name', :as_cassette do
          before do
            post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains",
                 { domain: { name: 'abcdef@adomainthatishopefullynotusedontheplatform1.de' } }, request_headers
          end
          include_examples 'a semantically invalid request'
        end
        describe 'malformed name with multiple dots', :as_cassette do
          before do
            post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains",
                 { domain: { name: '...abc.adomainthatishopefullynotusedontheplatform2.de' } }, request_headers
          end
          include_examples 'a semantically invalid request'
        end
        describe 'malformed name with trailing dot', :as_cassette do
          before do
            post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains",
                 { domain: { name: '...abc.adomainthatishopefullynotusedontheplatform3.de.' } }, request_headers
          end
          include_examples 'a semantically invalid request'
        end
      end
      describe 'with missing name', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains",
               { domain: {} }, request_headers
        end
        include_examples 'a bad request'
      end
    end

    describe 'succeeds' do
      describe 'with hostname in the name', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains",
               { domain: { name: "#{@endpoint}.adomainthatishopefullynotusedontheplatform.de" } }, request_headers
        end
        include_examples 'a valid POST request'
        include_examples 'domain entity schema'
        it 'has valid name property' do
          expect(json_body[:name]).to eql("#{@endpoint}.adomainthatishopefullynotusedontheplatform.de")
        end
      end

      describe 'without hostname in the name', :as_cassette do
        before do
          post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains",
               { domain: { name: 'adomainthatishopefullynotusedontheplatform.de' } }, request_headers
        end
        include_examples 'a valid POST request'
        include_examples 'domain entity schema'
        it 'has valid name property' do
          expect(json_body[:name]).to eql('adomainthatishopefullynotusedontheplatform.de')
        end
      end
    end
  end
end

shared_examples 'valid:applications:domains:create:422' do
  describe 'domains create fails', cassette_group: 'app-domains;create' do
    describe 'if the name is already used', :as_cassette do
      before do
        post "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains",
             { domain: { name: "#{@endpoint}.adomainthatishopefullynotusedontheplatform.de" } }, request_headers
      end
      include_examples 'a semantically invalid request'
      it 'bad request refers to already taken name' do
        expect(json_body[:dev_message]).to include('already')
      end
    end
  end
end

shared_examples 'valid:applications:domains:get' do
  describe 'domains get', cassette_group: 'app-domains;get' do
    describe 'succeeds' do
      describe 'with hostname', :as_cassette do
        before do
          # fetch the ID of the domain. CF does not allow access by name
          get("/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains", request_headers)
          domain_id = json_body[:domains].find do |d|
            d[:name] == "#{@endpoint}.adomainthatishopefullynotusedontheplatform.de"
          end[:id]
          get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains/#{domain_id}", request_headers
        end
        include_examples 'a valid GET request'
        include_examples 'domain entity schema'
        it 'has valid name property' do
          expect(json_body[:name]).to eql("#{@endpoint}.adomainthatishopefullynotusedontheplatform.de")
        end
      end

      describe 'without hostname', :as_cassette do
        before do
          # fetch the ID of the domain. CF does not allow access by name
          get("/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains", request_headers)
          domain_id = json_body[:domains].find { |d| d[:name] == 'adomainthatishopefullynotusedontheplatform.de' }[:id]
          get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains/#{domain_id}", request_headers
        end
        include_examples 'a valid GET request'
        include_examples 'domain entity schema'
        it 'has valid name property' do
          expect(json_body[:name]).to eql('adomainthatishopefullynotusedontheplatform.de')
        end
      end
    end

    describe 'fails for non-existent domain', :as_cassette do
      before do
        get "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/domains/unknown_domain", request_headers
      end
      include_examples 'an unknown requested resource'
    end
  end
end

shared_examples 'valid:applications:domains:delete' do
  describe 'domains delete', cassette_group: 'app-domains;delete' do
    describe 'succeeds' do
      describe 'for previously created entity with hostname', :as_cassette do
        before do
          # fetch the ID of the domain. CF does not allow access by name
          get("/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains", request_headers)
          domain_id = json_body[:domains].find do |d|
            d[:name] == "#{@endpoint}.adomainthatishopefullynotusedontheplatform.de"
          end[:id]
          delete "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains/#{domain_id}", {}, request_headers
        end
        include_examples 'a valid DELETE request'
      end
      describe 'for previously created entity without hostname', :as_cassette do
        before do
          # fetch the ID of the domain. CF does not allow access by name
          get("/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains", request_headers)
          domain_id = json_body[:domains].find { |d| d[:name] == 'adomainthatishopefullynotusedontheplatform.de' }[:id]
          delete "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains/#{domain_id}", {}, request_headers
        end
        include_examples 'a valid DELETE request'
      end
    end

    describe 'fails for' do
      describe 'non-existing domain id', :as_cassette do
        before do
          delete "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/domains/unknown_domain", {}, request_headers
        end
        include_examples 'an unknown requested resource'
      end

      describe 'non-existing application', :as_cassette do
        before do
          delete "/endpoints/#{@endpoint}/applications/app_never_exists_0123456789/domains/"\
                 'adomainthatishopefullynotusedontheplatform%2Ede', {}, request_headers
        end
        include_examples 'an unknown requested resource'
      end
    end
  end
end
