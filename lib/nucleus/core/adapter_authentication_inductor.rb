module Nucleus
  # The {AdapterAuthenticationInductor} patches adapter classes so that each method that is defined in the AdapterStub
  # of the current API version is wrapped with the {Nucleus::Adapters::AuthenticationRetryWrapper}.
  module AdapterAuthenticationInductor
    include Nucleus::Logging

    # Patch the adapter instance and use the authentication information of the environment.
    # @param [Nucleus::Adapters::BaseAdapter] adapter_instance the adapter implementation instance to patch
    # @param [Hash<String, String>] env environment which includes the HTTP authentication header
    # @return [void]
    def self.patch(adapter_instance, env)
      stub_class(adapter_instance).instance_methods(false).each do |method_to_wrap|
        # wrap method with authentication repetition call
        patch_method(adapter_instance, method_to_wrap, env)
      end
    end

    # Patch the actual method that is defined in an API version stub.
    # The method shall than be able to update the authentication token if the initial authentication expired.<br>
    # Only major authentication issues, e.g. if the credentials are repeatedly rejected,
    # will be thrown to the adapter caller.
    # @param [Nucleus::Adapters::BaseAdapter] adapter the adapter implementation to patch
    # @param [Symbol] method_to_wrap method that shall be patched
    # @param [Hash<String, String>] env environment which includes the HTTP authentication header
    # @return [void]
    # @private
    def self.patch_method(adapter, method_to_wrap, env)
      with_wrapper = :"#{method_to_wrap}_with_before_each_method_call"
      without_wrapper = :"#{method_to_wrap}_without_before_each_method_call"
      # patching should be done only once, return if method is already patched (!)
      return if adapter.respond_to?(with_wrapper) && adapter.respond_to?(without_wrapper)

      @__last_methods_added = [method_to_wrap, with_wrapper, without_wrapper]
      # wrap the method call
      adapter.class.send :define_method, with_wrapper do |*args, &block|
        log.debug "Calling adapter method '#{method_to_wrap}' against #{endpoint_url}"
        # use the AuthenticationRetryWrapper to retry calls if tokens expired, ...
        Nucleus::Adapters::AuthenticationRetryWrapper.with_authentication(adapter, env) do
          return send without_wrapper, *args, &block
        end
      end
      # now do the actual method re-assignment
      adapter.class.send :define_method, without_wrapper, adapter.method(method_to_wrap)
      adapter.class.send :define_method, method_to_wrap, adapter.method(with_wrapper)
      @__last_methods_added = nil
    end
    private_class_method :patch_method

    # @private
    def self.stub_class(adapter)
      parent = adapter.class
      loop do
        break if parent.superclass == Adapters::BaseAdapter
        parent = parent.superclass
      end
      parent
    end
    private_class_method :stub_class
  end
end
