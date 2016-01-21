require 'English'

module Nucleus
  module Logging
    class Formatter
      FORMAT = "%s, %38s [%s#%d] %5s -- %s: %s\n".freeze

      attr_accessor :datetime_format

      def initialize
        @datetime_format = nil
      end

      def call(severity, time, progname, msg)
        request_part = if Thread.current[:nucleus_request_id].nil?
                         # if there is no request id, then fill up the space
                         "[#{'*' * 36}]"
                       else
                         "[#{Thread.current[:nucleus_request_id]}]"
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
          "#{msg.message} (#{msg.class})\n" << (msg.backtrace || []).join("\n")
        else
          msg.inspect
        end
      end
    end
  end
end
