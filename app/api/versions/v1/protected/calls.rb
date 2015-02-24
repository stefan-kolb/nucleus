module Paasal
  module API
    module V1
      class Calls < Grape::API
        helpers Paasal::SharedParamsHelper

        # TODO: define tests for both methods and some calls with varying http_methods
        # TODO: test with post, or anything else

        resource :endpoints do
          params do
            use :endpoint_id
          end
          resource ':endpoint_id/call' do
            route :any, '*path' do
              log.debug("Native endpoint call with params: #{params}")
              call_path = params.delete :path
              call_method = env['REQUEST_METHOD'].to_sym
              with_authentication { adapter.endpoint_call call_method, call_path, params }
            end
          end

          params do
            use :application_context
          end
          resource ':endpoint_id/applications/:application_id/call' do
            route :any, '*path' do
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
