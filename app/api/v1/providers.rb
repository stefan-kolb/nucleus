module Paasal
  module API
    module V1
      class Providers < Grape::API
        format :json
        version 'v1', using: :path, vendor: 'paasal', format: :json

        resource :providers do
          desc "Return list of providers"
          get do

            #adapters = ObjectSpace.each_object(Paasal::PaasProvider).select { |klass| klass < self }

            {heroku:'heroku',cloudFoundry:'cloudFoundry'}
          end

          get do
            # TODO get a specific provider
            # TODO find provider adapter
            # TODO find provider version
            # TODO
          end

          get ':id', requirements: { id: /[0-9]*/ } do
            {a:'a'}
          end

          namespace :outer, requirements: { id: /[0-9]*/ } do
            get :id do
              {b:'b'}
            end

            get ":id/edit" do
              {c:'c'}
            end
          end
        end

=begin
        resource "providers/:providerName/:providerVersion" do
          params do
            requires :providerVersion, type: String, desc: "The version of the provider's API"
            requires :providerName, type: String, desc: "The provider that shall be used"
          end
          get do
            {
                d:'d',
                name: params[:providerName],
                version: params[:providerVersion]
            }
          end
        end
=end

      end
    end
  end
end