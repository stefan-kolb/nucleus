module Paasal
  module API
    module V1
      class Acme < Grape::API
        format :json
        version [ 'v2', 'v1' ], using: :path, vendor: 'paasal', format: :json

        desc "Returns the current API version, v1."
        get do
          { version: 'v1' }
        end

        desc "Returns pong."
        get "ping" do
          { ping: "pong1" }
        end
      end
    end
  end
end