module Nucleus
  module Adapters
    module V1
      class Heroku < Stub
        module Domains
          # As of now, there is no update functionality on Heroku as on most other platforms (!)

          # @see Stub#domains
          def domains(application_id)
            domains = get("/apps/#{application_id}/domains").body
            # exclude web_url by domain, otherwise we would need to fire an additional query and get the application
            domains.delete_if { |domain| domain[:hostname].end_with? ".#{@endpoint_app_domain}" }
            domains.collect { |domain| to_nucleus_domain(domain) }
          end

          # @see Stub#domain
          def domain(application_id, domain_id)
            domain = get("/apps/#{application_id}/domains/#{domain_id}").body
            to_nucleus_domain(domain)
          end

          # @see Stub#create_domain
          def create_domain(application_id, domain)
            domain = post("/apps/#{application_id}/domains", body: { hostname: domain[:name] }).body
            to_nucleus_domain(domain)
          end

          # @see Stub#delete_domain
          def delete_domain(application_id, domain_id)
            delete("/apps/#{application_id}/domains/#{domain_id}")
          end

          private

          def to_nucleus_domain(domain)
            domain[:name] = domain.delete :hostname
            domain
          end
        end
      end
    end
  end
end
