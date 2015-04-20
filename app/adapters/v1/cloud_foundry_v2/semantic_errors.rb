module Paasal
  module Adapters
    module V1
      class CloudFoundryV2 < Stub
        module SemanticErrors
          ERROR_MESSAGES = {
            only_one_runtime: { code: 422_200_1, message: 'Cloud Foundry V2 only allows 1 runtime per application' },
            build_in_progrss: { code: 422_200_2, message: 'Application build is still in progress' },
            no_space_assigned: { code: 422_200_3, message: 'User is not assigned to any space' },
            service_not_bindable: { code: 422_200_4, message: "Can't add service '%s' to the application: "\
              'The service does not allow to be bound to applications.' },
            service_not_active: { code: 422_200_5, message: "Can't add service '%s' to the application: "\
              'The service does is not active, thus does not allow to create a new instance to bind to the app.' },
            service_not_updateable: { code: 422_200_6, message: "Can't change service '%s' to the new plan: "\
              'The service does not allow to update the plan.' }
          }

          def fail_with(error_name, params = nil)
            error = ERROR_MESSAGES[error_name]
            fail Errors::PlatformSpecificSemanticError.new(error[:message] % params, error[:code])
          end
        end
      end
    end
  end
end
