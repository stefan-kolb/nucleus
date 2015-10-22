module Nucleus
  module API
    module V1
      class ApplicationData < Grape::API
        helpers SharedParamsHelper

        params do
          use :application_context
        end
        resource 'endpoints/:endpoint_id/applications/:application_id/data', desc: 'Application data',
                 swagger: { nested: false, name: 'application-data' } do
          desc 'Deploy the application' do
            failure [[204, 'Application data deployed']].concat ErrorResponses.standard_responses
          end
          params do
            requires :file, desc: 'The application data to deploy, compressed as .zip, .tar or .tar.gz archive',
                     type: ::Rack::Multipart::UploadedFile
          end
          post '/deploy' do
            # pattern matches filename?
            name_match = /^.+\.(zip|tar|tgz|tar.gz)$/.match(params[:file][:filename])
            content_type_match = %w(application/zip application/gzip application/x-gzip).include? params[:file][:type]

            fail Nucleus::Errors::AdapterRequestError,
                 "Invalid 'file'. Must contain the archive format" unless name_match || content_type_match

            # convert content type to compression format when name was not matched
            if name_match
              compression_format = name_match[1]
            else
              case params[:file][:type]
              when 'application/zip'
                compression_format = 'zip'
              when 'application/gzip'
                compression_format = 'tar.gz'
              when 'application/x-gzip'
                compression_format = 'tar.gz'
              end
            end

            adapter.deploy(params[:application_id], params[:file].tempfile, compression_format)
            # TODO: what shall we return here? application or 204
            # do not include any data in the response
            status 204
          end

          desc 'Rebuild the application' do
            success Models::Application
            failure [[200, 'Application rebuild done', Models::Application]].concat ErrorResponses.standard_responses
          end
          post '/rebuild' do
            present adapter.rebuild(params[:application_id]), with: Models::Application
          end

          desc 'Download the application data, binary attachment' do
            # TODO: response format, recently not possible with grape-swagger
            failure [[200, 'Application downloaded']].concat ErrorResponses.standard_responses
          end
          params do
            optional :archive_format, desc: 'Compression format to use for the returned application archive, '\
                     'one of: \'zip\', \'tar.gz\'. Defaults to \'zip\'.',
                     values: Nucleus::API::Enums::CompressionFormats.all,
                     default: Nucleus::API::Enums::CompressionFormats::ZIP
          end
          get '/download' do
            compression_format = params[:archive_format]
            data = adapter.download(params[:application_id], compression_format)
            filename = "#{params[:endpoint_id]}.app.source.#{params[:application_id]}.#{compression_format}"
            content_type MIME::Types.of(filename).first.content_type
            env['api.format'] = :binary
            # header 'Content-Disposition', "attachment; filename*=UTF-8''#{URI.escape(filename)}"
            header 'Content-Disposition', "attachment; filename=#{URI.escape(filename)}"
            data.set_encoding('ASCII-8BIT').read
          end
        end # end of resource
      end
    end
  end
end
