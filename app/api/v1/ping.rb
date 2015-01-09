module Paasal
  module API
    module V1
      class Ping < Grape::API
        format :json
        version 'v1', using: :path, vendor: 'paasal', format: :json

        get '/ping' do
          { ping: 'pong' }
        end

      end
    end
  end
end