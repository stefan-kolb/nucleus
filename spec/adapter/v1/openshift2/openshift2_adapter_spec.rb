require 'spec/adapter/adapter_spec_helper'

describe Paasal::Adapters::V1::Openshift2Adapter do
  before do
    @endpoint = 'openshift-online'
    @adapter = load_adapter(@endpoint, 'v1')
  end

  context 'with invalid credentials' do
    let!(:request_headers) { credentials(@endpoint, false) }
    include_examples 'invalid:#authenticate'
    include_examples 'compliant adapter with invalid credentials'
  end

  describe 'with missing credentials' do
    let!(:request_headers) { {} }
    include_examples 'compliant adapter with invalid credentials'
  end

  context 'with valid credentials' do
    let!(:request_headers) { credentials(@endpoint) }
    include_examples 'valid:#authenticate'
    include_examples 'compliant adapter with valid credentials'
  end
end
