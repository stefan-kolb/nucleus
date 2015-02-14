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
