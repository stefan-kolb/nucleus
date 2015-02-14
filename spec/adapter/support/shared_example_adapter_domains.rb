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
