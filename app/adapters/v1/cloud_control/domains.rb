module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        # cloud control, CRUD operations for the application's domain object
        module Domains
          # cloud control URLs that are automatically assigned to applications as domain but can't be managed
          CC_URLS = %w(cloudcontrolapp.com cloudcontrolled.com)

          # @see Stub#domains
          def domains(application_id)
            # no conversion needed, cc domains already have :name value
            cc_domains = get("/app/#{application_id}/deployment/#{PAASAL_DEPLOYMENT}/alias").body
            # the domain shall NOT be a CC system domain
            cc_domains.find_all { |domain| !CC_URLS.any? { |cc_domain| domain[:name].include? cc_domain } }.compact
            cc_domains.collect { |domain| to_paasal_domain(domain) }
          end

          # @see Stub#domain
          def domain(application_id, alias_name)
            # no conversion needed, cc domains already have :name value
            cc_domain = get("/app/#{application_id}/deployment/#{PAASAL_DEPLOYMENT}/alias/#{alias_name}").body
            to_paasal_domain(cc_domain)
          end

          # @see Stub#create_domain
          def create_domain(application_id, domain)
            # no conversion needed, cc domains already have :name value
            cc_domain = post("/app/#{application_id}/deployment/#{PAASAL_DEPLOYMENT}/alias",
                             body: { name: domain[:name] }).body
            log.info("Please use this code to verify your custom application domain: #{cc_domain[:verification_code]}")
            log.info('More information about the domain verification can be found at: '\
              'https://www.cloudcontrol.com/dev-center/add-on-documentation/alias')
            to_paasal_domain(cc_domain)
          end

          # @see Stub#delete_domain
          def delete_domain(application_id, alias_name)
            delete("/app/#{application_id}/deployment/#{PAASAL_DEPLOYMENT}/alias/#{alias_name}")
          end

          private

          def to_paasal_domain(domain)
            domain[:id] = domain[:name]
            domain
          end
        end
      end
    end
  end
end
