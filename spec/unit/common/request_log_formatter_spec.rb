describe Paasal::Logging::Formatter do
  subject { Paasal::Logging::Formatter.new }
  let(:request_id) { SecureRandom.uuid }
  let(:severity) { Logger::Severity::WARN.to_s }
  let(:time) { Time.now }
  let(:prog) { 'progname' }
  let(:msg) { 'This output shall be included in the log' }

  # make sure paasal_request_id is always reset
  before(:each) { Thread.current[:paasal_request_id] = nil }

  context 'with paasal_request_id assigned to the current thread' do
    before do
      Thread.current[:paasal_request_id] = request_id
      @response = subject.call(severity, time, prog, msg)
    end

    it 'does include the request_id' do
      expect(@response).to include(request_id)
    end
    it 'includes the program name' do
      expect(@response).to include(prog)
    end
    it 'includes the actual log message' do
      expect(@response).to include(msg)
    end
    it 'ends with a newline' do
      expect(@response).to end_with("\n")
    end
  end

  context 'paasal_request_id unassigned' do
    let(:dateformat) { '%Y-%m-%d' }
    before do
      subject.datetime_format = dateformat
      @response = subject.call(severity, time, prog, msg)
    end

    it 'does not include the request_id' do
      expect(@response).to_not include(request_id)
    end
    it 'includes the program name' do
      expect(@response).to include(prog)
    end
    it 'includes the actual log message' do
      expect(@response).to include(msg)
    end
    it 'ends with a newline' do
      expect(@response).to end_with("\n")
    end
    it 'does included the time formatted according to the specified format' do
      expect(@response).to include(time.strftime(dateformat))
    end
  end

  context 'paasal_request_id unassigned' do
    before { @response = subject.call(severity, time, prog, msg) }

    it 'does not include the request_id' do
      expect(@response).to_not include(request_id)
    end
    it 'includes the program name' do
      expect(@response).to include(prog)
    end
    it 'includes the actual log message' do
      expect(@response).to include(msg)
    end
    it 'ends with a newline' do
      expect(@response).to end_with("\n")
    end
  end

  context 'with an exception as error message' do
    let(:error) { StandardError.new(msg) }
    before { @response = subject.call(severity, time, prog, error) }

    it 'does not include the request_id' do
      expect(@response).to_not include(request_id)
    end
    it 'includes the program name' do
      expect(@response).to include(prog)
    end
    it 'includes the actual log message' do
      expect(@response).to include(msg)
    end
    it 'ends with a newline' do
      expect(@response).to end_with("\n")
    end
  end

  context 'with an object as error message' do
    let(:object) { { hashkey: 'hashvalue' } }
    before { @response = subject.call(severity, time, prog, object) }

    it 'does not include the request_id' do
      expect(@response).to_not include(request_id)
    end
    it 'includes the program name' do
      expect(@response).to include(prog)
    end
    it 'includes the actual log message' do
      expect(@response).to include(object.inspect)
    end
    it 'ends with a newline' do
      expect(@response).to end_with("\n")
    end
  end
end
