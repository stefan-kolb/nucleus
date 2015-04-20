module Paasal
  module Adapters
    module V1
      class CloudFoundryV2 < Stub
        module SemanticErrors
          ERROR_MESSAGES = {
            only_one_runtime: { code: 422_200_1, message: 'Cloud Foundry V2 only allows 1 runtime per application' },
            build_in_progrss: { code: 422_200_2, message: 'Application build is still in progress' },
            no_space_assigned: { code: 422_200_3, message: 'User is not assigned to any space' }
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
