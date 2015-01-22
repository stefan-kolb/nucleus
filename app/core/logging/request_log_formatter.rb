require 'english'

module Paasal
  module Logging
    class Formatter
      FORMAT = "%s, %38s [%s#%d] %5s -- %s: %s\n"

      attr_accessor :datetime_format

      def initialize
        @datetime_format = nil
      end

      def call(severity, time, progname, msg)
        if Thread.current[:paasal_request_id].nil?
          # if there is no request id, then fill up the space
          request_part = "[#{'*' * 36}]"
        else
          request_part = "[#{Thread.current[:paasal_request_id]}]"
        end

        format(FORMAT, severity[0..0], request_part, format_datetime(time),
               $PID, severity, progname, msg2str(msg))
      end

      private

      def format_datetime(time)
        if @datetime_format.nil?
          format(time.strftime('%Y-%m-%dT%H:%M:%S.') << '%06d ', time.usec)
        else
          time.strftime(@datetime_format)
        end
      end

      def msg2str(msg)
        case msg
        when ::String
          msg
        when ::Exception
          "#{ msg.message } (#{ msg.class })\n" << (msg.backtrace || []).join("\n")
        else
          msg.inspect
        end
      end
    end
  end
end
