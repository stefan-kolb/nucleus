module Paasal
  module API
    module V2
      class Base < Grape::API
        format :json
        version 'v2', using: :path, vendor: 'paasal', format: :json, cascade: true

        mount Paasal::API::V2::Acme

        add_swagger_documentation
      end
    end
  end
end