module Paasal
  module API
    # API {V1} is the first API version of Nucleus to be released.
    # Please have a look at the README file or the {Paasal::Adapters::V1::Stub} adapter for a detailed list of features.
    module V1
      # The {Base} class of API version 1 includes all routes, endpoints and the swagger documentation to be build.
      class Base < Grape::API
        # specify the version for all mounted endpoints
        version 'v1', using: :header, vendor: 'paasal', format: :json

        before do
          # allow no declared version for api root
          if version.nil?
            if env['HTTP_ACCEPT_VERSION']
              # Fallback for swagger-ui. If no version could be used from the accept header,
              # try to use the accept-version header.
              env['api.version'] = env['HTTP_ACCEPT_VERSION']
            else
              # Without a version Nucleus can't work properly, fail fast (!)
              to_error(ErrorMessages::INVALID_ACCEPT_HEADER,
                       'Make sure you provided a valid Accept Header, eg: \'application/vnd.paasal-v1+json\'')
            end
          end
        end

        # dynamic mounting is not possible due to incompatibility with grape-swagger
        mount V1::Vendors
        mount V1::Providers
        mount V1::Endpoints
        mount V1::Auth

        get '/resources' do
          # TODO: move to helper and reuse in later versions
          resource_names = %w(vendors providers endpoints)
          resource_hashes = []
          resource_names.each do |version_resource|
            resource_hashes << {
              name: version_resource,
                link: "#{request.url}/#{version_resource}"
            }
          end

          version_base = { name: 'v1', resources: resource_hashes }
          present version_base, with: Models::ApiVersion
        end

        add_swagger_documentation api_version: version, mount_path: '/schema',
                                  hide_documentation_path: true, info: paasal_config.api,
                                  specific_api_documentation: { desc: 'Platform as a Service abstraction layer '\
                                  'API swagger-compatible endpoint documentation.' }
      end
    end
  end
end
