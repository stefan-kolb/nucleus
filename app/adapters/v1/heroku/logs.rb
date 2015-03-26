module Paasal
  module Adapters
    module V1
      class Heroku < Stub
        module Logs
          def available_log_types
            log_types = {}
            log_types[API::Application::LogfileType::API] = { source: 'heroku', dyno: 'api' }
            log_types[API::Application::LogfileType::APPLICATION] = { source: 'app' }
            log_types[API::Application::LogfileType::REQUEST] = { source: 'heroku', dyno: 'router' }
            # TODO: filter only for web and worker dynos (must be merged manually :/)
            log_types[API::Application::LogfileType::SYSTEM] = { source: 'heroku' }
            log_types
          end

          def request_body(log_id)
            return {} if log_id == :all
            available_log_types[log_id]
          end

          def logs(application_id)
            # fails with 404 if application is not available
            get("/apps/#{application_id}")

            available_log_files = []
            available_log_types.keys.each do |type|
              available_log_files.push(id: type, name: type, type: type)
            end
            available_log_files
          end

          def log?(application_id, log_id)
            # fails with 404 if application is not available
            get("/apps/#{application_id}")

            return true if log_id.to_sym == :all
            return true if log_id.to_sym == :build
            available_log_types.key? log_id.to_sym
          end

          def tail(application_id, log_id, stream)
            # Currently no tailing for build log possible
            if log_id == API::Application::LogfileType::BUILD
              entries = build_log_entries(application_id)
              entries.each { |entry| stream.send_message(entry) }
              stream.close
            else
              request_body = request_body(log_id.to_sym).merge(tail: true)
              log = post("/apps/#{application_id}/log-sessions", body: request_body).body
              http_connection = EventMachine::HttpRequest.new(log[:logplex_url])
              http_client = http_connection.get
              # close stream on error
              http_client.on_error do
                log.debug('CF log tail client error, close stream...')
                stream.close
              end
              # tail and immediately push the results to the stream
              http_client.stream { |chunk| stream.send_message(chunk) }
              # return object that responds to :stop and cancels the tailing request
              TailStopper.new(http_connection, :close)
            end
          end

          def build_log_entries(application_id)
            build_list = get("/apps/#{application_id}/builds").body
            # limitation: show only the last 3 builds
            entries = []
            build_list.last(3).each do |build|
              entries.push(*build_result_entries(application_id, build[:id]))
            end
            entries
          end

          def build_result_entries(application_id, build_id)
            build_result = get("/apps/#{application_id}/builds/#{build_id}/result").body
            entries = []
            build_result[:lines].each do |line_entry|
              # skip all blank lines
              next if line_entry[:line].strip.empty?
              # push and remove all trailing newline characters
              entries.push line_entry[:line].chomp('')
            end
            entries
          end

          def log_entries(application_id, log_id)
            return build_log_entries(application_id) if log_id.to_sym == API::Application::LogfileType::BUILD

            request_body = request_body(log_id.to_sym).merge(tail: false)
            log = post("/apps/#{application_id}/log-sessions", body: request_body).body
            logfile = get(log[:logplex_url], headers: {}).body
            # process to entries
            entries = []
            logfile.split(CRLF).each do |logfile_line|
              entries.push logfile_line
            end
            entries
          end
        end
      end
    end
  end
end
