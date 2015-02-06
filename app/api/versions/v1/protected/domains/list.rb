module Paasal
  module API
    module V1
      module Domains
        class List < Grape::API
          helpers Paasal::SharedParamsHelper

          resource :endpoints do
            desc 'List of domains under which the application is available' do
              success Models::Domains
              failure [[200, 'Domains retrieved', Models::Domains]].concat ErrorResponses.standard_responses
            end
            params do
              use :application_context
            end
            get ':endpoint_id/applications/:application_id/domains' do
              domains = with_authentication { adapter.domains(params[:application_id]) }
              present domains, with: Models::Domains
            end
          end #end of resource
        end
      end
    end
  end
end
