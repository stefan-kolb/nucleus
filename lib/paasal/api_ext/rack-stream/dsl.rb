module Rack
  class Stream
    module DSL
      def self.included(base)
        base.extend ClassMethods
        base.extend Forwardable

        base.class_eval do
          unless base.respond_to? :call
            include InstanceMethods
            attr_reader :env
          end

          def_delegators :"env['rack.stream']", :after_open, :before_chunk, :chunk, :after_chunk, :before_close,
                         :close, :after_close, :stream_transport, :after_connection_error
        end
      end
    end
  end
end
#
# THIS IS A MONKEY PATCH TO PROVIDE THE LOST CONNECTION CALLBACK FEATURE AS SUBMITTED IN THE PR #6
# SEE ALSO: https://github.com/intridea/rack-stream/pull/6
#
