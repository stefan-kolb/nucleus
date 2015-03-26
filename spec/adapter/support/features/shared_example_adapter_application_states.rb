shared_examples 'application state: created' do
  it 'application state is: created' do
    expect(json_body[:state]).to eql('created')
  end
end

shared_examples 'application state: stopped' do
  it 'application state is: stopped' do
    expect(json_body[:state]).to eql('stopped')
  end
end

shared_examples 'application state: running' do
  it 'application state is: running' do
    expect(json_body[:state]).to eql('running')
  end
end

shared_examples 'application state: deployed' do
  it 'application state is: deployed' do
    expect(json_body[:state]).to eql('deployed')
  end
end
