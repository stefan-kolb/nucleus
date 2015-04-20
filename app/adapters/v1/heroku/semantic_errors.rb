module Paasal
  module Adapters
    module V1
      class Heroku < Stub
        module SemanticErrors
          ERROR_MESSAGES = {
            need_verification: { code: 422_100_1,
                                 message: 'Heroku requires a billing account to allow this action: %s' },
            no_autoscale: { code: 422_100_2, message: 'Can\'t use \'autoscale\' on Heroku' },
            invalid_runtime: { code: 422_100_3,
                               message: 'Invalid runtime: %s is neither a known runtime, nor a buildpack URL' }
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
