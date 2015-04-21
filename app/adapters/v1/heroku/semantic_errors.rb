module Paasal
  module Adapters
    module V1
      class Heroku < Stub
        module SemanticErrors
          def semantic_error_messages
            {
              need_verification: { code: 422_100_1,
                                   message: 'Heroku requires a billing account to allow this action: %s' },
              no_autoscale: { code: 422_100_2, message: 'Can\'t use \'autoscale\' on Heroku' },
              invalid_runtime: { code: 422_100_3,
                                 message: 'Invalid runtime: %s is neither a known runtime, nor a buildpack URL' }
            }
          end
        end
      end
    end
  end
end
