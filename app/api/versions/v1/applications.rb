module Paasal
  module API
    module V1
      class Applications < Grape::API

        # starting at this API level, we require the user's authentication
        http_digest({ realm: 'Test Api', opaque: 'app secret' }) do |username|
          # lookup the user's password here
          { 'user1' => 'password1' }[username]
        end

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