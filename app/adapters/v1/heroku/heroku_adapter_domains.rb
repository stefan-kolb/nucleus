module Paasal
  module Adapters
    module V1
      module HerokuAdapterDomains
        # As of now, there is no update functionality on Heroku as on most other platforms (!)

        def domains(application_id)
          domains = get("/apps/#{application_id}/domains").body
          # exclude web_url by domain, otherwise we would need to fire an additional query and get the application
          domains.delete_if { |domain| domain[:hostname].end_with? ".#{@endpoint_app_domain}" }
          domains.collect { |domain| to_paasal_domain(domain) }
        end

        def domain(application_id, domain_id)
          domain = get("/apps/#{application_id}/domains/#{domain_id}").body
          to_paasal_domain(domain)
        end

        def create_domain(application_id, domain)
          domain = post("/apps/#{application_id}/domains", body: { hostname: domain[:name] }).body
          to_paasal_domain(domain)
        end

        def delete_domain(application_id, domain_id)
          delete("/apps/#{application_id}/domains/#{domain_id}")
        end

        private

        def to_paasal_domain(domain)
          domain[:name] = domain.delete :hostname
          domain
        end
      end
    end
  end
end
