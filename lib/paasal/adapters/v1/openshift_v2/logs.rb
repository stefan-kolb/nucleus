require 'time'
require 'net/ssh'

module Paasal
  module Adapters
    module V1
      class OpenshiftV2 < Stub
        module Logs
          # @see Stub#logs
          def logs(application_id)
            # fails with 404 if application is not available
            app = get("/application/#{app_id_by_name(application_id)}").body[:data]
            # ssh uri
            uri = ssh_uri(app)

            with_ssh_key do
              remote_log_files(uri, app[:creation_time])
            end
          end

          # @see Stub#log?
          def log?(application_id, log_id)
            # fails with 404 if application is not available
            app = get("/application/#{app_id_by_name(application_id)}").body[:data]
            # ssh uri
            uri = ssh_uri(app)

            with_ssh_key do
              remote_log_file?(uri)
            end
          end

          # @see Stub#tail
          def tail(application_id, log_id, stream)
            # TODO: implement me
            # remote_cmd = "tail#{options.opts ? ' --opts ' + Base64::encode64(options.opts).chomp : ''} #{file_glob}"
            # ssh_cmd = "ssh -t #{uuid}@#{host} '#{remote_cmd}'"
            fail NOT_IMPLEMENTED_ERROR
          end

          # @see Stub#log_entries
          def log_entries(application_id, log_id)
            # fails with 404 if application is not available
            app = get("/application/#{app_id_by_name(application_id)}").body[:data]
            # ssh uri
            uri = ssh_uri(app)

            with_ssh_key do
              remote_log_entries(uri, application_id, log_id)
            end
          end

          private

          def ssh_uri(application)
            URI.parse(application[:ssh_url])
          end

          def remote_log_files(uri, app_creation_time)
            available_log_files = []
            # ssh into main instance
            Net::SSH.start(uri.host, uri.user, keys: [paasal_config.ssh.handler.key_file]) do |ssh|
              # https://developers.openshift.com/en/managing-log-files.html#log-location
              log_files = ssh.exec!('ls $OPENSHIFT_LOG_DIR')

              log_files.split("\n").each do |file|
                updated_at = ssh.exec!("date -r $OPENSHIFT_LOG_DIR/#{file}")
                updated_at = Time.parse(updated_at).utc.iso8601
                # TODO: no unified naming among cartridges: ApplicationLogfileType::APPLICATION by default.
                available_log_files.push(id: File.basename(file, '.*'), name: file,
                                         type: Enums::ApplicationLogfileType::APPLICATION,
                                         created_at: app_creation_time, updated_at: updated_at)
              end
            end
            available_log_files
          end

          def remote_log_file?(uri)
            Net::SSH.start(uri.host, uri.user, keys: [paasal_config.ssh.handler.key_file]) do |ssh|
              remote_file_exists?(ssh, "#{log_id}.log")
            end
          end

          def remote_log_entries(uri, app_id, log_id)
            Net::SSH.start(uri.host, uri.user, keys: [paasal_config.ssh.handler.key_file]) do |ssh|
              # log exists?
              unless remote_file_exists?(ssh, "#{log_id}.log")
                fail Errors::AdapterResourceNotFoundError,
                     "Invalid log file '#{log_id}', not available for application '#{app_id}'"
              end
              # process log
              log = ssh.exec!("cat $OPENSHIFT_LOG_DIR/#{log_id}.log")
              log.split("\n")
            end
          end

          def remote_file_exists?(connection, file)
            # file exists? 1 : 0
            exists = connection.exec!("[ ! -f $OPENSHIFT_LOG_DIR/#{file} ]; echo $?").strip
            exists == '1'
          end
        end
      end
    end
  end
end
