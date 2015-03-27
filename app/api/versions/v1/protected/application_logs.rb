module Paasal
  module API
    module V1
      class ApplicationLogs < Grape::API
        helpers Paasal::SharedParamsHelper
        helpers Paasal::StreamingHelper

        # TODO: find a way to describe the actual response formats with grape-swagger

        params do
          use :application_context
        end
        resource 'endpoints/:endpoint_id/applications/:application_id/logs',  desc: 'Application logs',
                 swagger: { nested: false, name: 'application-logs' } do
          desc 'List all application log files' do
            success Models::Logs
            failure [[200, 'Logs retrieved', Models::Logs]].concat ErrorResponses.standard_responses
          end
          get '/' do
            logs = with_authentication { adapter.logs(params[:application_id]) }
            present logs, with: Models::Logs
          end

          desc 'Download all log files as archive' do
            failure [[200, 'Logfile archive']].concat ErrorResponses.standard_responses
          end
          params do
            optional :archive_format, desc: 'Compression format to use for the returned application archive, '\
                     'one of: \'zip\', \'tar.gz\'. Defaults to \'zip\'.',
                     values: Paasal::API::CompressionFormats.all,
                     default: Paasal::API::CompressionFormats::ZIP
          end
          get '/download' do
            # returns an array of log entries
            logs = with_authentication { adapter.logs(params[:application_id]) }
            archive_filename = "paasal.app.generic.logs.download.#{params[:application_id]}"\
              ".#{SecureRandom.uuid}.#{params[:archive_format]}"
            tmp_dir = File.join(Dir.tmpdir, archive_filename)

            # prepare response
            env['api.format'] = :binary
            # header 'Content-Disposition', "attachment; filename*=UTF-8''#{URI.escape(archive_filename)}"
            header 'Content-Disposition', "attachment; filename=#{URI.escape(archive_filename)}"
            content_type MIME::Types.of(archive_filename).first.content_type

            begin
              # be sure that directory exists
              FileUtils.mkdir_p(tmp_dir, verbose: false)
              valid_logfiles = 0
              logs.each do |logfile|
                log.debug "Including #{logfile[:id]} in archive download"
                log_entries = with_authentication { adapter.log_entries(params[:application_id], logfile[:id]) }
                next unless log_entries && log_entries.length > 0
                data = StringIO.new(log_entries.join("\r\n"))
                filename = "#{params[:endpoint_id]}.app.#{params[:application_id]}.#{logfile[:id]}.log"
                file_path = File.join(tmp_dir, filename)
                # write log entries to a file
                File.open(file_path, 'wb') { |f| f.print data.read }
                valid_logfiles += 1
              end

              if valid_logfiles == 0
                # no logs with entries found? fail!
                fail Errors::AdapterResourceNotFoundError,
                     "No non-empty log available for application '#{params[:application_id]}'"
              end

              # when all log files were written to disk, pack them and return the data
              Paasal::Archiver.new.compress(tmp_dir, params[:archive_format]).read
            ensure
              # make sure tmp directory is deleted again
              FileUtils.rm_rf(tmp_dir)
            end
          end

          params do
            use :log_id
          end
          resource '/:log_id' do
            desc 'Show a log file' do
              success Models::Log
              failure [[200, 'Logs retrieved', Models::Log]].concat ErrorResponses.standard_responses
            end
            get '/' do
              # execute the actual request and fetch the log
              log_entries = with_authentication do
                # returns an array of log entries
                adapter.log_entries(params[:application_id], params[:log_id])
              end

              status 200
              header 'Content-Type', 'text/plain'
              env['api.format'] = :txt
              log_entries.join("\r\n")
            end

            desc 'Download a log file' do
              failure [[200, 'Logfile']].concat ErrorResponses.standard_responses
            end
            params do
              optional :file_format, desc: 'File format to use for the returned logfile, '\
                'one of: \'log\', \'zip\', \'tar.gz\'. Defaults to \'txt\'.',
                       values: Paasal::API::LogDownloadFormats.all,
                       default: Paasal::API::LogDownloadFormats::LOG
            end
            get '/download' do
              # returns an array of log entries
              log_entries = with_authentication { adapter.log_entries(params[:application_id], params[:log_id]) }
              data = StringIO.new(log_entries.join("\r\n"))
              filename = "#{params[:endpoint_id]}.app.#{params[:application_id]}.log."\
                "#{params[:log_id]}.#{params[:file_format]}"
              env['api.format'] = :binary
              # header 'Content-Disposition', "attachment; filename*=UTF-8''#{URI.escape(filename)}"
              header 'Content-Disposition', "attachment; filename=#{URI.escape(filename)}"

              if params[:file_format].to_s == 'log'
                content_type 'text/plain'
                data.read
              else
                content_type MIME::Types.of(filename).first.content_type
                file_path = "#{Dir.tmpdir}/#{filename}"
                begin
                  # write file to disk
                  File.open(file_path, 'wb') { |f| f.print data.read }
                  archiver = Paasal::Archiver.new
                  # pack and return the data
                  archiver.compress(file_path, params[:file_format]).read
                ensure
                  # make sure tmp directory is deleted again
                  FileUtils.rm_rf(file_path)
                end
              end
            end

            desc 'Tail a log file and receive updates with the chunked response' do
              failure [[200, 'Returning chunked log file contents']].concat ErrorResponses.standard_responses
            end
            get '/tail' do
              begin

              # we need to check file existence before, otherwise we would have returned status 200 already
              log_exists = with_authentication { adapter.log?(params[:application_id], params[:log_id]) }
              unless log_exists
                fail Errors::AdapterResourceNotFoundError,
                     "Invalid log file '#{params[:log_id]}', not available for application '#{params[:application_id]}'"
              end

              tail_polling = nil
              stream = RackStreamCallback.new(self)
              after_connection_error do
                # tidy resource when the connection was terminated with an error
                log.debug('Connection error reported by rack-stream')
                stream.closed = true
                close
              end

              after_open do
                begin
                  # execute the actual request and stream the logging message
                  tail_polling = with_authentication { adapter.tail(params[:application_id], params[:log_id], stream) }
                rescue StandardError => e
                  stream.closed = true
                  close
                end
              end

              before_close do
                log.debug 'Closing API stream, stop tail updates...'
                tail_polling.stop if tail_polling
              end

              status 200
              header 'Content-Type', 'text/html'
              # TODO: will be included in response, can this be avoided or is this standard conform?
              ''
              rescue StandardError => e
                p e
                e.backtrace.each { |line| p line }
              end
            end
          end
        end # end of resource
      end
    end
  end
end
