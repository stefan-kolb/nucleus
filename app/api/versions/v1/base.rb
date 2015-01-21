module Paasal
  module API
    module V1
      class Base < Grape::API
        # specify the version for all mounted endpoints
        version 'v1', using: :path, vendor: 'paasal', format: :json

        # dynamic mounting is not possible due to incompatibility with grape-swagger
        mount V1::Providers
        mount V1::Endpoints
        mount V1::Vendors
        mount V1::Auth

        get '/' do
          # TODO move to helper and reuse in later versions
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
                                  hide_documentation_path: true, info: configatron.api,
                                  specific_api_documentation: { desc: 'Platform as a Service abstraction layer '\
                                  'API swagger-compatible endpoint documentation.' }
      end
    end
  end
end
