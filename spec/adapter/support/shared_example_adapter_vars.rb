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

shared_examples 'valid:vars:list' do
  xit 'list env_vars' do
    # TODO: implement this test
  end
end

shared_examples 'valid:vars:get:404' do
  xit 'get non-existent env_var fails' do
    # TODO: implement this test
  end
end

shared_examples 'valid:vars:create' do
  describe 'create env_var fails' do
    xit 'with missing properties' do
      # TODO: implement this test
    end
    xit 'with invalid properties' do
      # TODO: implement this test
    end
  end

  xit 'create env_var' do
    # TODO: implement this test
  end
end

shared_examples 'valid:vars:update' do
  xit 'update env_var' do
    # TODO: implement this test
  end
end

shared_examples 'valid:vars:get' do
  xit 'get env_var' do
    # TODO: implement this test
  end
end

shared_examples 'valid:vars:delete' do
  xit 'delete env_var' do
    # TODO: implement this test
  end
end
