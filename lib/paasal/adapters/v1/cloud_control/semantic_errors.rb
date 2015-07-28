module Paasal
  module Adapters
    module V1
      class CloudControl < Stub
        # Semantic error messages that are specific for cloudControl
        module SemanticErrors
          # Get all cloudControl specific semantic error definitions.
          # @return [Hash<Symbol,Hash<Symbol,String>>] the error message definitions, including the error +code+,
          #   e.g. +422_200_1+ and the +message+ that shall be formatted when used.
          def semantic_error_messages
            {
              # Error code '300_1': Only one runtime is allowed per cloudControl application
              only_one_runtime: { code: 422_300_1, message: 'cloudControl only allows 1 runtime per application' },
              # Error code '300_2': Billing details required
              billing_required: { code: 422_300_2,
                                  message: 'cloudControl requires a billing account to allow this action: %s' },
              # Error code '300_3': Malformed name, please follow the requirements of cloudControl app names
              bad_name: { code: 422_300_3, message: '%s' },
              # Error code '300_3': Malformed name, please follow the requirements of cloudControl app names
              ambiguous_deployments: { code: 422_300_4, message: 'Unable to identify the deployment that shall be '\
                'used. PaaSal require to find: a) exactly one deployment, b) a "default" deployment or '\
                'c) a "paasal" deployment' },
              no_deployment: { code: 422_300_5, message: 'No deployment found. PaaSal requires to find: a) '\
                'exactly one deployment, b) a "default" deployment or c) a "paasal" deployment' }
            }
          end
        end
      end
    end
  end
end
