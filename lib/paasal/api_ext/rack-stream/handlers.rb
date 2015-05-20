module Rack
  class Stream
    module Handlers
      class AbstractHandler
        def initialize(app)
          @app  = app
          @body = DeferrableBody.new
          @body.errback { @app.report_connection_error }
        end
      end
    end
  end
end
#
# THIS IS A MONKEY PATCH TO PROVIDE THE LOST CONNECTION CALLBACK FEATURE AS SUBMITTED IN THE PR #6
# SEE ALSO: https://github.com/intridea/rack-stream/pull/6
#
