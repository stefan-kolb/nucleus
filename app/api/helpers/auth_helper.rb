module Paasal
  module AuthHelper
    extend Grape::API::Helpers
    include Paasal::Logging

    # Executes a block, which should be an adapter call, using the authentication information.
    # If the first call fails due to cached authentication information, the cache is going to get evicted,
    # authentication repeated and finally the call will be executed again.
    #
    # @return [Hash, void] result of the yield block execution, usually a Hash matching the Grape::Entity to represent
    def with_authentication
      Adapters::AuthenticationRetryWrapper.with_authentication(adapter, @env) do
        yield
      end
    end
  end
end
