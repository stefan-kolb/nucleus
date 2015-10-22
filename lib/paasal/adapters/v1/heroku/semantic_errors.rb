module Nucleus
  module Adapters
    module V1
      class Heroku < Stub
        # Semantic error messages that are specific for Heroku
        module SemanticErrors
          # Get all Heroku specific semantic error definitions.
          # @return [Hash<Symbol,Hash<Symbol,String>>] the error message definitions, including the error +code+,
          #   e.g. +422_200_1+ and the +message+ that shall be formatted when used.
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
