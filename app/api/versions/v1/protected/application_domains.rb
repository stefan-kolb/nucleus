module Paasal
  module API
    module V1
      class ApplicationDomains < Grape::API
        helpers Paasal::SharedParamsHelper

        params do
          use :application_context
        end
        resource 'endpoints/:endpoint_id/applications/:application_id/domains', desc: 'Application domain operations',
                 swagger: { nested: false, name: 'application-domains' } do
          desc 'List of domains under which the application can be accessed' do
            success Models::Domains
            failure [[200, 'Domains retrieved', Models::Domains]].concat ErrorResponses.standard_responses
          end
          get '/' do
            domains = with_authentication { adapter.domains(params[:application_id]) }
            present domains, with: Models::Domains
          end

          desc 'Create a domain' do
            success Models::Domain
            failure [[201, 'Domain created',
                      Models::Domain]].concat ErrorResponses.standard_responses
          end
          params do
            requires :domain, type: Hash do
              # we only need the domain name
              requires :all, using: Paasal::API::Models::Domain.documentation.slice(:name)
            end
          end
          post '/' do
            domain_params = declared(params, include_missing: false)[:domain]
            unless /(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}$)/ =~ domain_params[:name]
              fail Errors::SemanticAdapterRequestError, "'#{domain_params[:name]}'' is not a valid domain name"
            end

            domain = with_authentication { adapter.create_domain(params[:application_id], domain_params) }
            present domain, with: Models::Domain
          end

          params do
            use :domain_id
          end
          # regex to allow dots in the domain as path element
          resource '/:domain_id', requirements: { domain_id: /.*/ } do
            desc 'Show a domain' do
              success Models::Domain
              failure [[200, 'Domain retrieved',
                        Models::Domains]].concat ErrorResponses.standard_responses
            end
            get '/' do
              domain = with_authentication { adapter.domain(params[:application_id], params[:domain_id]) }
              present domain, with: Models::Domain
            end

            desc 'Delete a domain' do
              success Models::Domain
              failure [[200, 'Domain deleted',
                        Models::Domains]].concat ErrorResponses.standard_responses
            end
            delete '/' do
              with_authentication { adapter.delete_domain(params[:application_id], params[:domain_id]) }
              # respond with 204 when entity is deleted (see rfc7231)
              status 204
            end
          end
        end # end of resource
      end
    end
  end
end
