shared_examples 'an unknown requested resource' do
  it 'has status 404' do
    expect(response.status).to eq(404)
  end
end

shared_examples 'an unauthorized request' do
  it 'has status 401' do
    expect(response.status).to eq(401)
  end
end

shared_examples 'a valid GET request' do
  it 'has status 200' do
    expect(response.status).to eq(200)
  end
end

shared_examples 'a valid POST request' do
  it 'has status 201' do
    expect(response.status).to eq(201)
  end
end

shared_examples 'a malformed POST request' do
  it 'has status 400' do
    expect(response.status).to eq(400)
  end
end

shared_examples 'a valid PATCH request' do
  it 'has status 200' do
    expect(response.status).to eq(200)
  end
end

shared_examples 'a malformed PATCH request' do
  it 'has status 400' do
    expect(response.status).to eq(400)
  end
end

shared_examples 'a valid DELETE request' do
  it 'has status 204' do
    expect(response.status).to eq(204)
  end
end
