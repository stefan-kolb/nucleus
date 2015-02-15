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

shared_examples 'valid:domains:list' do
  xit 'list domains' do
    # TODO: implement this test
  end
end

shared_examples 'valid:domains:get:404' do
  xit 'get non-existent domain fails' do
    # TODO: implement this test
  end
end

shared_examples 'valid:domains:create' do
  describe 'create domain fails' do
    xit 'with invalid properties' do
      # TODO: implement this test
    end
    xit 'with missing properties' do
      # TODO: implement this test
    end
  end

  xit 'create domain' do
    # TODO: implement this test
  end
end

shared_examples 'valid:domains:update' do
  xit 'update domain' do
    # TODO: implement this test
  end
end

shared_examples 'valid:domains:get' do
  xit 'get domain' do
    # TODO: implement this test
  end
end

shared_examples 'valid:domains:delete' do
  xit 'delete domain' do
    # TODO: implement this test
  end
end
