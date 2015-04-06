shared_examples 'valid:applications:scale:400' do
  describe 'scale fails' do
    describe 'with missing instances property', :as_cassette do
      before do
        post "/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}/actions/scale",
             {}, request_headers
      end
      include_examples 'a bad request'
      it 'refers to missing instances property' do
        expect(json_body[:dev_message]).to include('instances is missing')
      end
    end
    describe 'with 0 instances value', :as_cassette do
      before do
        post "/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}/actions/scale",
             { instances: 0 }, request_headers
      end
      include_examples 'a bad request'
      it 'refers to negative instances property' do
        expect(json_body[:dev_message]).to include('instances does not have a valid value')
      end
    end
    describe 'with negative instances value', :as_cassette do
      before do
        post "/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}/actions/scale",
             { instances: -1 }, request_headers
      end
      include_examples 'a bad request'
      it 'refers to negative instances property' do
        expect(json_body[:dev_message]).to include('instances does not have a valid value')
      end
    end
    describe 'with invalid instances property type', :as_cassette do
      before do
        post "/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}/actions/scale",
             { instances: 'abc' }, request_headers
      end
      include_examples 'a bad request'
      it 'refers to invalid instances property' do
        expect(json_body[:dev_message]).to include('instances does not have a valid value')
      end
    end
  end
end

shared_examples 'valid:applications:scale' do
  describe 'scale-out and add an application instance', :as_cassette do
    before do
      post "/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}/actions/scale",
           { instances: 2 }, request_headers
    end
    include_examples 'a valid POST request'
    it 'changes instances property of the application' do
      expect(json_body[:instances]).to eql(2)
    end
  end

  describe 'scale-in and remove an application instance', :as_cassette do
    before do
      post "/endpoints/#{@endpoint}/applications/#{@app_min[:updated_name]}/actions/scale",
           { instances: 1 }, request_headers
    end
    include_examples 'a valid POST request'
    it 'changes instances property of the application' do
      expect(json_body[:instances]).to eql(1)
    end
  end
end
