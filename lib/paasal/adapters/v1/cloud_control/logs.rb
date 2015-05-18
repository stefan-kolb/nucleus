module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        # cloud control application's log management operations
        module Logs
          # Cloud control log types. The +key+ and +id+ shall match the PaaSal definitions of log files,
          # whereas the +name+ shall match the cloud control log id.
          LOG_TYPES = {
            all: { id: 'all', name: 'all', type: API::Enums::ApplicationLogfileType::OTHER },
            request: { id: 'request', name: 'access', type: API::Enums::ApplicationLogfileType::REQUEST },
            application: { id: 'application', name: 'error', type: API::Enums::ApplicationLogfileType::APPLICATION },
            api: { id: 'api', name: 'deploy', type: API::Enums::ApplicationLogfileType::API },
            system: { id: 'system', name: 'worker', type: API::Enums::ApplicationLogfileType::SYSTEM }
          }

          # @see Stub#logs
          def logs(application_name)
            # fails with 404 if application is not available and serves for timestamps
            app = get("/app/#{application_name}").body

            LOG_TYPES.values.collect do |log|
              log[:created_at] = app[:date_created]
              log[:updated_at] = app[:date_modified]
              log
            end
          end

          # @see Stub#log?
          def log?(application_name, log_id)
            # fails with 404 if application is not available
            get("/app/#{application_name}")

            LOG_TYPES.key? log_id.to_sym
          end

          # cloud control shows the last 500 log messages if applicable
          # @see Stub#tail
          def tail(application_name, log_id, stream)
            # cache headers as they are bound to a request and could be lost with the next tick
            headers_to_use = headers
            logs_to_poll = log_id == 'all' ? LOG_TYPES.keys - [:all] : [log_id]
            poller = LogPoller.new(self, headers_to_use)
            poller.start(application_name, logs_to_poll, stream)
            TailStopper.new(poller, :stop)
          end

          # cloud control shows the last 500 log messages if applicable
          # @see Stub#log_entries
          def log_entries(application_name, log_id)
            unless log?(application_name, log_id)
              fail Errors::AdapterResourceNotFoundError,
                   "Invalid log file '#{log_id}', not available for application '#{application_name}'"
            end
            if log_id == 'all'
              fetched_lines = []
              (LOG_TYPES.keys - [:all]).each do |current_log_id|
                cc_log_entries(application_name, current_log_id).each do |line|
                  line[:paasal_origin] = current_log_id
                  fetched_lines.push(line)
                end
              end
              fetched_lines.sort! { |line_1, line_2| line_1[:time] <=> line_2[:time] }
              fetched_lines.collect { |line| format_log_entry(line[:paasal_origin], line) }
            else
              cc_log_entries(application_name, log_id).collect { |line| format_log_entry(log_id, line) }
            end
          end

          private

          def cc_log_entries(app_name, log_id, time = nil, headers_to_use = nil)
            log_name = LOG_TYPES[log_id.to_sym][:name]
            # Hack, do not create fresh headers (which would fail) when in a deferred action
            headers_to_use = headers unless headers_to_use
            if time
              get("/app/#{app_name}/deployment/#{PAASAL_DEPLOYMENT}/log/#{log_name}?timestamp=#{time}",
                  headers: headers_to_use).body
            else
              get("/app/#{app_name}/deployment/#{PAASAL_DEPLOYMENT}/log/#{log_name}", headers: headers_to_use).body
            end
          end

          def format_log_entry(log_id, line)
            # format according to: https://github.com/cloudControl/cctrl/blob/master/cctrl/output.py
            case log_id.to_sym
            when :request
              "#{line[:remote_host]} #{line[:remote_user]} #{line[:remote_logname]} [#{Time.at(line[:time]).iso8601}] "\
                "#{line[:first_request_line]} #{line[:status]} #{line[:response_size_CLF]} #{line[:referer]} "\
                "#{line[:user_agent]}"
            when :system
              "#{line[:time]} #{line[:wrk_id]} #{line[:message]}"
            when :build
              "#{Time.at(line[:time]).iso8601} [#{line[:hostname]}/#{line[:depl_id]}] #{line[:level]} #{line[:message]}"
            when :error
              "#{line[:time]} #{line[:type]} #{line[:message]}"
            end
          end
        end
      end
    end
  end
end
