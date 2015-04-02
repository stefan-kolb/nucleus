module Paasal
  module API
    module V1
      class ApplicationLogs < Grape::API
        helpers Paasal::SharedParamsHelper

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
                data = StringIO.new(log_entries.join("\n"))
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
              Paasal::Archiver.new.compress(tmp_dir, params[:archive_format]).set_encoding('ASCII-8BIT').read
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
              log_entries.join("\n")
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
              data = StringIO.new(log_entries.join("\n"))
              filename = "#{params[:endpoint_id]}.app.#{params[:application_id]}.log."\
                "#{params[:log_id]}.#{params[:file_format]}"

              env['api.format'] = :binary
              # header 'Content-Disposition', "attachment; filename*=UTF-8''#{URI.escape(filename)}"
              header 'Content-Disposition', "attachment; filename=#{URI.escape(filename)}"

              if params[:file_format].to_s == 'log'
                content_type 'text/plain'
                return data.read
              else
                tmp_dir = File.join(Dir.tmpdir, "#{params[:endpoint_id]}.app.#{params[:application_id]}.download."\
                  "log.#{params[:log_id]}.#{SecureRandom.uuid}")
                raw_filename = "#{params[:endpoint_id]}.app.#{params[:application_id]}.log.#{params[:log_id]}.log"
                content_type MIME::Types.of(filename).first.content_type
                begin
                  # write file to disk
                  FileUtils.mkdir_p(tmp_dir)
                  File.open(File.join(tmp_dir, raw_filename), 'wb') { |f| f.print data.read }
                  archiver = Paasal::Archiver.new
                  # pack and return the data
                  return archiver.compress(tmp_dir, params[:file_format]).set_encoding('ASCII-8BIT').read
                ensure
                  # make sure tmp directory is deleted again
                  FileUtils.rm_rf(tmp_dir)
                end
              end
            end
          end
        end # end of resource
      end
    end
  end
end
