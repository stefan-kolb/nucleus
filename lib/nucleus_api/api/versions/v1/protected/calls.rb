module Nucleus
  module API
    module V1
      class Calls < Grape::API
        helpers SharedParamsHelper

        params do
          use :endpoint_id
        end
        namespace 'endpoints/:endpoint_id/call', desc: 'Native API calls',
                  swagger: { name: 'endpoint-native-calls', nested: false } do
          %w(get post patch put delete).each do |http_method|
            desc "Execute a native #{http_method.upcase} API call against the endpoint"
            params do
              requires :path, type: String, desc: 'The URL path to call at the endpoint'
            end
            route http_method.to_sym, '*path' do
              log.debug("Native endpoint call with params: #{params}")
              call_path = params.delete :path
              call_method = env['REQUEST_METHOD'].to_sym
              with_authentication { adapter.endpoint_call call_method, call_path, params }
            end
          end
        end
      end
    end
  end
end
