shared_examples 'contains the request ID' do
  it 'has a request id' do
    expect(headers['X-Request-ID']).to_not be_nil
  end
end

shared_examples 'valid error schema' do
  it 'complies with the error schema' do

  end
  it 'status matches error schema status' do
    expect(json_body[:status]).to eq(response.status)
  end
  it 'has a developer message' do
    expect(json_body[:dev_message]).to_not be_nil
    expect(json_body[:dev_message].strip.length).to be > 0
  end
end

shared_examples 'an unknown requested resource' do
  include_examples 'contains the request ID'
  it 'has status 404' do
    expect_status 404
  end
end

shared_examples 'an unauthorized request' do
  include_examples 'contains the request ID'
  it 'has status 401' do
    expect_status 401
  end
end

shared_examples 'a bad request' do
  include_examples 'contains the request ID'
  include_examples 'valid error schema'
  it 'has status 400' do
    expect_status 400
  end
  it 'has a developer message' do
    expect(json_body[:dev_message]).to_not be_nil
    expect(json_body[:dev_message]).to_not be_nil
  end
end

shared_examples 'a not accepted request' do
  include_examples 'contains the request ID'
  include_examples 'valid error schema'
  it 'has status 406' do
    expect_status 406
  end
end

shared_examples 'a valid GET request' do
  include_examples 'contains the request ID'
  it 'has status 200' do
    expect_status 200
  end
end

shared_examples 'a valid POST request' do
  include_examples 'contains the request ID'
  it 'has status 201' do
    expect_status 201
  end
end

shared_examples 'a valid PATCH request' do
  include_examples 'contains the request ID'
  it 'has status 200' do
    expect_status 200
  end
end

shared_examples 'a valid DELETE request' do
  include_examples 'contains the request ID'
  it 'has status 204' do
    expect_status 204
  end
end
