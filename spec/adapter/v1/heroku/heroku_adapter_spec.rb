require 'spec/adapter/adapter_spec_helper'

describe Paasal::Adapters::V1::HerokuAdapter do
  before do
    @endpoint = 'heroku'
    @adapter = load_adapter(@endpoint, 'v1')
  end

  context 'with invalid credentials' do
    let!(:request_headers) { credentials(@endpoint, false) }

    include_examples 'invalid: #authenticate'
    include_examples 'invalid: list applications'
  end

  describe 'with missing credentials' do
    let!(:request_headers) { {} }

    include_examples 'invalid: list applications'
  end

  context 'with valid credentials' do
    let!(:request_headers) { credentials(@endpoint) }

    include_examples 'valid: #authenticate'
    include_examples 'valid: list applications'
  end
end
