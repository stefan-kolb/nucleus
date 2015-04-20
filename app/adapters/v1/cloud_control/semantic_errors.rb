module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        module SemanticErrors
          ERROR_MESSAGES = {
            # Error code '300_1': Only one runtime is allowed per cloudControl application
            only_one_runtime: { code: 422_300_1, message: 'cloudControl only allows 1 runtime per application' },
            # Error code '300_2': Billing details required
            billing_required: { code: 422_300_2,
                                message: 'cloudControl requires a billing account to allow this action: %s' },
            # Error code '300_3': Malformed name, please follow the requirements of cloudControl app names
            bad_name: { code: 422_300_3, message: '%s' }
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
