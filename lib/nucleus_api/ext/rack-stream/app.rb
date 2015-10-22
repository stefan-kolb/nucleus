module Rack
  class Stream
    class App
      def report_connection_error
        # notify callbacks about the connection error
        run_callbacks(:connection_error)
      end
      define_callbacks :connection_error, :after
    end
  end
end
#
# THIS IS A MONKEY PATCH TO PROVIDE THE LOST CONNECTION CALLBACK FEATURE AS SUBMITTED IN THE PR #6
# SEE ALSO: https://github.com/intridea/rack-stream/pull/6
#
