module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        # cloud control application's log management operations
        module Logs
          class LogPoller
            def initialize(adapter, headers_to_use)
              @adapter = adapter
              @headers_to_use = headers_to_use
            end

            # Start the continuous polling of the logs.
            # @param [String] application_name the name (the ID) of the application
            # @param [Array<String>] logs_to_poll IDs of the logs to poll
            # @param [RackStreamCallback] stream stream callback to push messages
            # @return [void]
            def start(application_name, logs_to_poll, stream)
              @polling_active = true
              # 1 log: wait 4 seconds between polls
              # 4 logs: 1 seconds
              timeout = logs_to_poll.length == 1 ? 4 : 1
              last_log_entry = {}
              logs_to_poll.each { |log_to_poll| last_log_entry[log_to_poll] = nil }

              fetch_action = lambda do
                logs_to_poll.each do |log_to_poll|
                  # check again if we are still supposed to be active
                  break unless @polling_active
                  lines = @adapter.send(:cc_log_entries, application_name, log_to_poll,
                                        last_log_entry[log_to_poll], @headers_to_use)
                  next if lines.empty?
                  # now sort by time
                  lines.sort! { |line_1, line_2| line_1[:time].to_f <=> line_2[:time].to_f }
                  last_log_entry[log_to_poll] = lines.last[:time] if lines
                  lines.each do |line|
                    line[:paasal_origin] = log_to_poll
                    stream.send_message(@adapter.send(:format_log_entry, line[:paasal_origin], line))
                  end
                end
                # start next iteration if we are still supposed to be active
                EM.add_timer(timeout) { fetch_action.call } if @polling_active
              end

              # start the loop to poll the logs
              EM.add_timer(timeout) { fetch_action.call }
            end

            # Stop the polling at the next shot
            def stop
              @polling_active = false
            end
          end
        end
      end
    end
  end
end
