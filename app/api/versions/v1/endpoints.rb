module Paasal
  module API
    module V1
      class Endpoints < Grape::API
        helpers Paasal::SharedParamsHelper

        resource :endpoints do

          # # LIST endpoints
          # desc 'List of available endpoints'
          # get '/' do
          #   endpoint_dao = Paasal::DB::EndpointDao.new self.version
          #   endpoints = endpoint_dao.all
          #   present endpoints, with: Models::Endpoints
          # end

          # GET endpoint
          desc 'Get a selected endpoint entity via its ID'
          params do
            use :endpoint_id
          end
          get ':endpoint_id' do
            present load_endpoint, with: Models::Endpoint
          end
        end # provider namespace
      end
    end
  end
end
