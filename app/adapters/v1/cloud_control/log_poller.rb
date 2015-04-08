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

            def start(application_name, logs_to_poll, stream)
              p 'start polling...'
              @polling_active = true
              # 1 log: wait 4 seconds between polls
              # 4 logs: 1 seconds
              timeout = logs_to_poll.length == 1 ? 4 : 1
              last_log_entry = {}
              logs_to_poll.each { |log_to_poll| last_log_entry[log_to_poll] = nil }

              fetch_action = lambda do
                p 'poll action started...'
                fetched_lines = []
                logs_to_poll.each do |log_to_poll|
                  p "poll for #{log_to_poll}"
                  # check again if we are still supposed to be active
                  break unless @polling_active
                  lines = @adapter.send(:cc_log_entries, application_name, log_to_poll,
                                        last_log_entry[log_to_poll], @headers_to_use)
                  unless lines.empty?
                    lines.each do |line|
                      line[:paasal_origin] = log_to_poll
                      fetched_lines.push(line)
                    end
                    last_log_entry[log_to_poll] = Time.at(lines.last[:time]).to_i if lines
                  end
                  p '...polling finished!'
                end
                # now sort by time
                fetched_lines.sort! { |line_1, line_2| line_1[:time] <=> line_2[:time] }
                # now push the sorted lines to the stream
                fetched_lines.each do |line|
                  stream.send_message(@adapter.send(:format_log_entry, line[:paasal_origin], line))
                end
                # start next iteration if we are still supposed to be active
                EM.add_timer(timeout) { fetch_action.call } if @polling_active
              end
              # start the loop to poll the logs
              EM.add_timer(timeout) { fetch_action.call }
            end

            def stop
              p 'stop polling'
              @polling_active = false
            end
          end
        end
      end
    end
  end
end
