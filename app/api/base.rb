module Paasal
  module API
    class Base < Grape::API
      desc 'This is the root of our API.'

      # list all API versions
      mount Paasal::API::Versions

      # ATTENTION (!) BE AWARE THAT THE APIs MUST ALWAYS
      # BE SORTED STARTING WITH THE HIGHEST VERSION

      # include proof-of-concept API, version 2
      mount Paasal::API::V2::Base

      # include basic API, version 1
      mount Paasal::API::V1::Base

      resource :providerx do
        desc "Return list of providers"
        get do
          {heroku:'heroku',cloudFoundry:'cloudFoundry'}
        end
      end

      add_swagger_documentation api_version: 'v1', mount_path: '/swagger/v1'
      add_swagger_documentation api_version: 'v2', mount_path: '/swagger/v2'
    end
  end
end