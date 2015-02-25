module Paasal
  module API
    module V1
      class Calls < Grape::API
        helpers Paasal::SharedParamsHelper

        helpers do
          params :api_call_path do
            requires :path, type: String, desc: 'The URL path to call at the endpoint'
          end
        end

        # TODO: test with post, or anything that requires a body

        resource :endpoints do
          %w(get post patch put delete).each do |http_method|
            desc "Execute a native #{http_method.upcase} API call against the endpoint"
            params do
              use :endpoint_id
              use :api_call_path
            end
            route http_method.to_sym, ':endpoint_id/call/*path' do
              log.debug("Native endpoint call with params: #{params}")
              call_path = params.delete :path
              call_method = env['REQUEST_METHOD'].to_sym
              with_authentication { adapter.endpoint_call call_method, call_path, params }
            end
          end

          %w(get post patch put delete).each do |http_method|
            desc "Execute a native #{http_method.upcase} API call against an endpoint's application"
            params do
              use :application_context
              use :api_call_path
            end
            route http_method.to_sym, ':endpoint_id/applications/:application_id/call/*path' do
              log.debug("Native application call with params: #{params}")
              call_path = params.delete :path
              call_method = env['REQUEST_METHOD'].to_sym
              with_authentication do
                adapter.application_call(params[:application_id], call_method, call_path, params)
              end
            end
          end
        end
      end
    end
  end
end
