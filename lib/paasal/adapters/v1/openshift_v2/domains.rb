module Nucleus
  module Adapters
    module V1
      class OpenshiftV2 < Stub
        module Domains
          # @see Stub#domains
          def domains(application_id)
            domains = get("/application/#{app_id_by_name(application_id)}/aliases").body[:data]
            domains.collect { |domain| to_paasal_domain(domain) }
          end

          # @see Stub#domain
          def domain(application_id, domain_id)
            to_paasal_domain get("/application/#{app_id_by_name(application_id)}/alias/#{domain_id}").body[:data]
          end

          # @see Stub#create_domain
          def create_domain(application_id, domain_entity)
            to_paasal_domain post("/application/#{app_id_by_name(application_id)}/aliases",
                                  body: { id: domain_entity[:name] }).body[:data]
          end

          # @see Stub#delete_domain
          def delete_domain(application_id, domain_id)
            delete("/application/#{app_id_by_name(application_id)}/alias/#{domain_id}")
          end

          private

          def to_paasal_domain(domain)
            { id: domain[:id], name: domain[:id], created_at: nil, updated_at: nil }
          end
        end
      end
    end
  end
end
