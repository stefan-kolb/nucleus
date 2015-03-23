module Paasal
  module Adapters
    module V1
      class CloudFoundry2 < BaseAdapter
        module Data
          def deploy(application_name_or_id, file, file_compression_format)
            # could be made async, too
            # resources: [] says that no previous data shall be reused, see also:
            # http://apidocs.cloudfoundry.org/202/apps/uploads_the_bits_for_an_app.html

            app_guid = app_guid(application_name_or_id)
            # deploy by guid
            # deploy_response = put("/v2/apps/#{app_guid}/bits", body: { resources: [], application: file.read },
            #                       headers: { 'Content-Type' => 'multipart/form-data; '\
            #                       'boundary=paasal-cloud-foundry-adapter-file-upload-boundary' })

            begin
              # convert all archives to .zip archives
              converted_file = ArchiveConverter.convert(file, file_compression_format, 'zip', true)
              unless converted_file.respond_to?(:path) && converted_file.respond_to?(:read)
                tmpfile = Tempfile.new(["paasal-deploy-upload-#{app_guid}", '.zip'])
                tmpfile.write converted_file.read
                tmpfile.rewind
                converted_file = tmpfile
              end

              # TODO: this is only a temporary solution until excon supports multipart requests
              # See also: https://github.com/excon/excon/issues/353
              url = "#{@endpoint_url}/v2/apps/#{app_guid}/bits"
              request_body = { multipart: true, application: converted_file, async: false, resources: '[]' }
              begin
                RestClient::Request.execute(method: :put, url: url, payload: request_body,
                                            headers: headers, verify_ssl: @check_certificates)
                # RestClient.put(url, request_body, headers)
              rescue RestClient::BadRequest => e
                raise Errors::BadRequestError, e.http_body
              end
            ensure
              if tmpfile
                tmpfile.close
                tmpfile.unlink
              end
            end
          end

          def download(application_name_or_id, compression_format)
            app_guid = app_guid(application_name_or_id)
            # fail if there is no deployment
            unless deployed?(app_guid)
              fail Errors::SemanticAdapterRequestError, 'Application must be deployed before data can be downloaded'
            end

            download_response = get("/v2/apps/#{app_guid}/download", follow_redirects: false, expects: [200, 302])
            if download_response.status == 200
              data = download_response.body
            else
              download_location = download_response.headers[:Location]
              # if IBM f*cked with the download URL, fix the address
              download_location.gsub!(/objectstorage.service.networklayer.com/, 'objectstorage.softlayer.net')
              data = Excon.get(download_location).body
            end
            # convert from current format (which is always a zip archive) to the destination format
            ArchiveConverter.convert(StringIO.new(data), 'zip', compression_format, false)
          end

          def rebuild(application_name_or_id)
            app_guid = app_guid(application_name_or_id)
            # fail if there is no deployment
            unless deployed?(app_guid)
              fail Errors::SemanticAdapterRequestError, 'Application must be deployed before it can be rebuild'
            end

            # rebuild by name or id
            rebuild_response = post("/v2/apps/#{app_guid}/restage")
            to_paasal_app(rebuild_response.body)
          end
        end
      end
    end
  end
end