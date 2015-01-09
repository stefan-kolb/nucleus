module Paasal
  module API
    module V1
      class Base < Grape::API
        format :json
        version 'v1', using: :path, vendor: 'paasal', format: :json, cascade: true

        mount Paasal::API::V1::Providers
        mount Paasal::API::V1::Acme

        #add_swagger_documentation api_version: 'v1', mount_path: '/docs'
      end
    end
  end
end