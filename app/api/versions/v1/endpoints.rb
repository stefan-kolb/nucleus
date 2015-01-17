module Paasal
  module API
    module V1
      class Endpoints < Grape::API

        helpers do
          # noinspection RubyArgCount
          params :endpoint_id do
            requires :endpoint_id, type: String, desc: "The endpoint's ID in the form of a UUID."
          end
        end

        resource :endpoints do

          # # LIST endpoints
          # desc 'List of available endpoints'
          # get '/' do
          #   endpoint_dao = Paasal::DB::EndpointDao.new self.version
          #   endpoints = endpoint_dao.get_all
          #   present endpoints, with: Models::Endpoints
          # end

          # GET endpoint
          desc 'Get a selected endpoint entity via its ID'
          params do
            use :endpoint_id
          end
          get ':endpoint_id' do
            endpoint_dao = Paasal::DB::EndpointDao.new self.version
            endpoint = endpoint_dao.get params[:endpoint_id]
            to_error(Errors::NOT_FOUND, "No endpoint found with the ID '#{params[:endpoint_id]}'") if endpoint.nil?
            present endpoint, with: Models::Endpoint
          end

          # TODO list all applications of this endpoint

        end

      end
    end
  end
end