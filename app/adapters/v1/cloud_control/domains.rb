module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        # cloud control, CRUD operations for the application's domain object
        module Domains
          # @see Stub#domains
          def domains(application_id)
            # TODO: implement me
          end

          # @see Stub#domain
          def domain(application_id, entity_id)
            # TODO: implement me
          end

          # @see Stub#create_domain
          def create_domain(application_id, entity_hash)
            # TODO: implement me
          end

          # @see Stub#delete_domain
          def delete_domain(application_id, entity_id)
            # TODO: implement me
          end
        end
      end
    end
  end
end
