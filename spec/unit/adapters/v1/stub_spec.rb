# Here we test that the Stub adapter always fails if an adapter implementation is missing
describe Nucleus::Adapters::V1::Stub do
  subject { Nucleus::Adapters::V1::Stub.new('https://example.org') }
  Nucleus::Adapters::V1::Stub.instance_methods(false).each do |method_name|
    it "#{method_name} shall fail with AdapterMissingImplementationError" do
      if subject.method(method_name).arity > 0
        args = Array.new(subject.method(method_name).arity, nil)
        expect { subject.send(method_name, *args) }.to raise_error(Nucleus::Errors::AdapterMissingImplementationError)
      else
        expect { subject.send(method_name) }.to raise_error(Nucleus::Errors::AdapterMissingImplementationError)
      end
    end
  end
end
