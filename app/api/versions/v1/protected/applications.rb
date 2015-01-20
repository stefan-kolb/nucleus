module Paasal
  module API
    module V1
      class Applications < Grape::API

        # TODO nested below endpoints
        resource :applications do

          get 'ping' do
            { response: 'pong' }
          end

        end

      end
    end
  end
end