module Paasal
  module API
    module V2
      class Acme < Grape::API
        format :json
        version 'v2', using: :path, vendor: 'paasal', format: :json

        desc "Returns the current API version, v2."
        get do
          { version: 'v2' }
        end
      end
    end
  end
end