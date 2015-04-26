# Here we test that the Stub adapter always fails if an adapter implementation is missing
describe Paasal::Adapters::V1::Stub do
  subject { Paasal::Adapters::V1::Stub.new('https://example.org') }
  Paasal::Adapters::V1::Stub.instance_methods(false).each do |method_name|
    it "#{method_name} shall fail with AdapterMissingImplementationError" do
      if subject.method(method_name).arity > 0
        args = Array.new(subject.method(method_name).arity, nil)
        expect { subject.send(method_name, *args) }.to raise_error(Paasal::Errors::AdapterMissingImplementationError)
      else
        expect { subject.send(method_name) }.to raise_error(Paasal::Errors::AdapterMissingImplementationError)
      end
    end
  end
end
