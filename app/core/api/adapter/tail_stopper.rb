module Paasal
  module Adapters
    # The TailStopper can be used to cancel a timer or an ongoing HTTP request,
    # e.g. when the underlying connection was terminated.
    class TailStopper
      include Paasal::Logging

      def initialize(polling, method_to_stop)
        @polling = polling
        @method_to_stop = method_to_stop
      end

      # Stop the tailing
      # @return [void]
      def stop
        log.debug('Stop tail updates, connection was closed')
        @polling.method(@method_to_stop).call
      end
    end
  end
end
