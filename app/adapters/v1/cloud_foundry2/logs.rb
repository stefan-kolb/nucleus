module Paasal
  module Adapters
    module V1
      module CloudFoundry2
        module Logs
          LOGGREGATOR_TYPES = [API::Application::LogfileType::API, API::Application::LogfileType::APPLICATION,
                               API::Application::LogfileType::REQUEST, API::Application::LogfileType::SYSTEM]
          CRLF = "\r\n"
          WSP  = "\s"

          def logs(application_name_or_id)
            app_guid = app_guid(application_name_or_id)
            available_log_files = []

            log_files_list = download_file(app_guid, 'logs', true)
            if log_files_list
              # parse raw response to array
              log_files_list.split(CRLF).each do |logfile_line|
                log_filename = logfile_line.rpartition(' ').first.strip
                if log_filename == 'staging_task.log'
                  log_type = API::Application::LogfileType::BUILD
                else
                  log_type = API::Application::LogfileType::OTHER
                end
                available_log_files.push(id: log_filename, name: log_filename, type: log_type)
              end
            end

            # add the default logtypes, available according to:
            # http://docs.cloudfoundry.org/devguide/deploy-apps/streaming-logs.html#format
            LOGGREGATOR_TYPES.each do |type|
              available_log_files.push(id: type, name: type, type: type)
            end
            # TODO: 'all' is probably not perfect, since the build wont be included
            available_log_files.push(id: 'all', name: 'all', type: API::Application::LogfileType::OTHER)
            available_log_files
          end

          def log?(app_guid, log_id)
            return true if log_stream? log_id
            # test file existence
            log_id = 'staging_task.log' if log_id.to_sym == API::Application::LogfileType::BUILD
            response = get("/v2/apps/#{app_guid}/instances/0/files/logs/#{log_id}",
                           follow_redirects: false, expects: [200, 302, 400])
            return true if response == 200
            return false if response == 400
            # if 302, followup
            begin
              # download log file
              download_file(app_guid, "logs/#{log_id}")
              # no error, file exists
              true
            rescue Errors::UnknownAdapterCallError, Excon::Errors::NotFound, Excon::Errors::BadRequest
              false
            end
          end

          def tail(application_name_or_id, log_id, stream)
            app_guid = app_guid(application_name_or_id)
            return tail_stream(app_guid, stream) if log_stream?(log_id)
            tail_file(app_guid, log_id, stream)
          end

          def log_entries(application_name_or_id, log_id)
            app_guid = app_guid(application_name_or_id)
            # first check if this log is a file or must be fetched from the loggregator
            if log_stream?(log_id)
              # fetch recent data from loggregator
              case log_id.to_sym
              when API::Application::LogfileType::API
                filter = ['API']
              when API::Application::LogfileType::APPLICATION
                filter = ['APP']
              when API::Application::LogfileType::REQUEST
                filter = ['RTR']
              when API::Application::LogfileType::SYSTEM
                filter = %w(STG LGR DEA)
              when :all
                # no filter, show all
                filter = nil
              else
                # invalid log requests --> 404
                fail Errors::AdapterResourceNotFoundError,
                     "Invalid log file '#{log_id}', not available for application '#{app_guid}'"
              end
              # returning an array of log entries
              recent_decoded = recent_log_messages(app_guid, filter)
              recent_decoded.collect { |log_msg| construct_log_entry(log_msg) }
            else
              # handle special staging log
              log_id = 'staging_task.log' if log_id.to_sym == API::Application::LogfileType::BUILD
              download_logfile_entries(app_guid, log_id)
            end
          end

          private

          def construct_log_entry(decoded_message)
            # 2015-03-22T15:28:55.83+0100 [RTR/0]      OUT message...
            "#{Time.at(decoded_message.timestamp / 1_000_000_000.0).iso8601} "\
              "[#{decoded_message.source_name}/#{decoded_message.source_id}] "\
              "#{decoded_message.message_type == 1 ? 'OUT' : 'ERR'} #{decoded_message.message}"
          end

          def download_logfile_entries(app_guid, log_id, headers_to_use = nil)
            # download log file
            logfile_contents = download_file(app_guid, "logs/#{log_id}", false, headers_to_use)
            # split file into entries by line breaks and return an array of log entries
            logfile_contents.split(CRLF)
          rescue Excon::Errors::NotFound
            raise Errors::AdapterResourceNotFoundError,
                  "Invalid log file '#{log_id}', not available for application '#{app_guid}'"
          end

          def download_file(app_guid, file_path, do_not_fail = false, headers_to_use = nil)
            expected_statuses = [200, 302]
            expected_statuses.push(400) if do_not_fail
            headers_to_use = headers unless headers_to_use
            # log list consists of 2 parts, loggregator and files
            log_files = get("/v2/apps/#{app_guid}/instances/0/files/#{file_path}",
                            follow_redirects: false, expects: expected_statuses, headers: headers_to_use)
            p log_files
            return nil if log_files.status == 400
            return log_files.body if log_files.status == 200

            # status must be 302, follow to the Location
            download_location = log_files.headers[:Location]
            # if IBM f*cked with the download URL, fix the address
            download_location.gsub!(/objectstorage.service.networklayer.com/, 'objectstorage.softlayer.net')
            Excon.defaults[:ssl_verify_peer] = false unless @check_certificates

            connection_params = { ssl_verify_peer: @check_certificates }
            connection = Excon.new(download_location, connection_params)
            connection.request(method: :get, expects: expected_statuses).body
          end

          def recent_log_messages(app_guid, filter = nil)
            loggregator_recent_uri = "https://#{loggregator_endpoint}:443/recent?app=#{app_guid}"
            # current log state before tailing, multipart message of protobuf objects
            current_log_response = get(loggregator_recent_uri)
            current_log_boundary = /boundary=(\w+)/.match(current_log_response.headers['Content-Type'])[1]
            current_log = current_log_response.body

            # TODO: improve this ugly piece of code to extract the message parts...
            boundary_regexp = /--#{Regexp.quote(current_log_boundary)}(--)?#{CRLF}/
            parts = current_log.split(boundary_regexp).collect do |chunk|
              header_part, _ = chunk.split(/#{CRLF}#{WSP}*#{CRLF}/m, 2)
              if header_part
                headers = header_part.split(/\r\n/).map { |kv| kv }
                headers.length > 1 ? headers[1] : nil
              end
            end.compact
            # decode log messages
            decoded_messages = parts.collect do |proto_message|
              p Paasal::Adapters::V1::CloudFoundry2::Logs::Message.decode(proto_message)
              Paasal::Adapters::V1::CloudFoundry2::Logs::Message.decode(proto_message)
            end.compact
            return decoded_messages unless filter
            # return filtered messages
            decoded_messages.find_all do |msg|
              filter.include?(msg.source_name)
            end
          end

          def log_stream?(log_id)
            LOGGREGATOR_TYPES.include?(log_id.to_sym) || log_id.to_sym == :all
          end

          def loggregator_endpoint
            @endpoint_url.gsub(%r{^(\w*://)?(api)([-\.\w]+)$}i, 'loggregator\3')
          end

          def tail_file(app_guid, log_id, stream)
            log.debug 'Tailing CF log file'
            log_id = 'staging_task.log' if log_id.to_sym == API::Application::LogfileType::BUILD

            # cache headers as they are bound to a request and could be lost with the next tick
            headers_to_use = headers
            latest_pushed_line = -1

            # update every 3 seconds
            @tail_file_timer = EM.add_periodic_timer(3) do
              log.debug('Poll updated file tail...')
              begin
                latest_pushed_line = push_file_tail(app_guid, log_id, stream, latest_pushed_line, headers_to_use)
              rescue Errors::AdapterResourceNotFoundError
                log.debug('Logfile not found, finished tailing')
                # file lost, close stream
                @tail_file_timer.cancel if @tail_file_timer
                stream.close
              end
            end
            # listener to stop polling
            StopListener.new(@tail_file_timer, :cancel)
          end

          def push_file_tail(app_guid, log_id, stream, pushed_line_idx, headers_to_use)
            log.debug('Fetching file for tail response...')
            entries = download_logfile_entries(app_guid, log_id, headers_to_use)
            # file was shortened, close stream since we do not know where to continue
            if entries.length < pushed_line_idx
              log.debug('File was modified and shortened, stop tailing the file...')
              stream.close
            else
              entries.each_with_index do |entry, index|
                next if index <= pushed_line_idx
                pushed_line_idx = index
                stream.send_message(entry)
              end
              pushed_line_idx
            end
          end

          def tail_stream(app_guid, stream)
            # push current state
            recent_log_messages(app_guid).each { |log_entry| stream.send_message(construct_log_entry(log_entry)) }

            # Now register websocket to receive the latest updates
            ws = Faye::WebSocket::Client.new("wss://#{loggregator_endpoint}:443/tail/?app=#{app_guid}",
                                             nil, headers: headers.slice('Authorization'))

            ws.on :message do |event|
              log.debug "CF loggregator message received: #{event}"
              begin
                msg = Paasal::Adapters::V1::CloudFoundry2::Logs::Message.decode(event.data.pack('C*'))
                # notify stream to print new log line
                stream.send_message(construct_log_entry(msg))
              rescue StandardError => e
                log.error "Cloud Foundry log message de-serialization failed: #{e}"
              end
            end

            ws.on :close do |event|
              log.debug "Closing CF loggregator websocket: code=#{event.code}, reason=#{event.reason}"
              ws = nil
              # notify stream that no more update are to arrive and stream shall be closed
              stream.close
            end
            # return listener to stop websocket
            StopListener.new(ws, :close)
          end

          # StopListener can be used to cancel a timer, e.g. when the underlying connection was terminated.
          class StopListener
            def initialize(polling, method_to_stop)
              @polling = polling
              @method_to_stop = method_to_stop
            end
            # Stop polling
            # @return [void]
            def stop
              log.debug('Stop tail updates, connection was closed')
              @polling.method(@method_to_stop).call
            end
          end

          # Message class definition, matching the Protocol Buffer definition of the Cloud Foundry loggregator.
          # see also: https://github.com/cloudfoundry/loggregatorlib/blob/master/logmessage/log_message.proto
          class Message < ::Protobuf::Message
            class MessageType < ::Protobuf::Enum
              define :OUT, 1
              define :ERR, 2
            end

            required :bytes, :message, 1
            required Logs::Message::MessageType, :message_type, 2
            required :sint64, :timestamp, 3
            required :string, :app_id, 4
            optional :string, :source_id, 6
            repeated :string, :drain_urls, 7
            optional :string, :source_name, 8
          end

          class Envelope < ::Protobuf::Message
            required :string, :routing_key, 1
            required :bytes, :signature, 2
            required Logs::Message, :log_message, 3
          end
        end
      end
    end
  end
end
