module Nucleus
  module Adapters
    module V1
      class Heroku < Stub
        module Logs
          # Carriage return (newline in Mac OS) + line feed (newline in Unix) == CRLF (newline in Windows)
          CRLF = "\r\n".freeze

          # @see Stub#logs
          def logs(application_id)
            # fails with 404 if application is not available and serves for timestamps
            app = get("/apps/#{application_id}").body

            available_log_files = []
            available_log_types.keys.each do |type|
              # TODO: right now, we always assume the log has recently been updated
              available_log_files.push(id: type, name: type, type: type,
                                       created_at: app[:created_at], updated_at: Time.now.utc.iso8601)
            end
            available_log_files
          end

          # @see Stub#log?
          def log?(application_id, log_id)
            # fails with 404 if application is not available
            get("/apps/#{application_id}")

            return true if log_id.to_sym == :all
            return true if log_id.to_sym == :build
            available_log_types.key? log_id.to_sym
          end

          # @see Stub#log_entries
          def log_entries(application_id, log_id)
            unless log?(application_id, log_id)
              raise Errors::AdapterResourceNotFoundError,
                    "Invalid log file '#{log_id}', not available for application '#{application_id}'"
            end

            return build_log_entries(application_id) if log_id.to_sym == Enums::ApplicationLogfileType::BUILD

            request_body = request_body(log_id.to_sym).merge(tail: false)
            log = post("/apps/#{application_id}/log-sessions", body: request_body).body
            logfile = get(log[:logplex_url], headers: {}).body
            # process to entries
            entries = []
            # skip empty logs, which are detected as Hash by the http client
            logfile.split(CRLF).each { |logfile_line| entries.push logfile_line } unless logfile == {}
            entries
          end

          # @see Stub#tail
          def tail(application_id, log_id, stream)
            # Currently no tailing for build log possible
            if log_id == Enums::ApplicationLogfileType::BUILD
              entries = build_log_entries(application_id)
              entries.each { |entry| stream.send_message(entry) }
              stream.close
            else
              request_body = request_body(log_id.to_sym).merge(tail: true)
              log = post("/apps/#{application_id}/log-sessions", body: request_body).body
              tail_http_response(log[:logplex_url], stream)
            end
          end

          private

          def available_log_types
            log_types = {}
            log_types[Enums::ApplicationLogfileType::API] = { source: 'heroku', dyno: 'api' }
            log_types[Enums::ApplicationLogfileType::APPLICATION] = { source: 'app' }
            log_types[Enums::ApplicationLogfileType::REQUEST] = { source: 'heroku', dyno: 'router' }
            # TODO: filter only for web and worker dynos (must be merged manually :/)
            log_types[Enums::ApplicationLogfileType::SYSTEM] = { source: 'heroku' }
            log_types
          end

          def request_body(log_id)
            return {} if log_id == :all
            available_log_types[log_id]
          end

          def build_log_entries(application_id)
            build_list = get("/apps/#{application_id}/builds").body
            # limitation: show only the last 3 builds
            entries = []
            build_list.last(3).each do |build|
              entries.concat(build_result_entries(application_id, build[:id]))
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
        end
      end
    end
  end
end
