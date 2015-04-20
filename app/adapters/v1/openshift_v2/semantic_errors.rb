module Paasal
  module Adapters
    module V1
      class OpenshiftV2 < Stub
        module SemanticErrors
          ERROR_MESSAGES = {
            # Error code '400_1': Only one runtime is allowed per Openshift V2 application
            only_one_runtime: { code: 422_400_1, message: 'Openshift V2 only allows 1 runtime per '\
              'application' },

            must_have_runtime: { code: 422_400_2, message: 'Openshift V2 requires you to specify exactly one runtime '\
              'when creating the application. Please provide a valid runtime in the next request.' },

            # Error code '400_3': Application is not scalable
            not_scalable: { code: 422_400_3, message: "Application '%s' is not scalable, "\
              "instances can't be adjusted" },

            # Error code '400_4': Quota exceeded, scaling would require more gears than available to the user
            insufficient_gears: { code: 422_400_4, message: "Application '%s' can't be, "\
              'scaled to %s instances, requires %s gears but only %s gears are available' },

            no_user_domain: { code: 422_400_5, message: "Openshift V2 requires you to create a 'domain' before "\
              'any application can be created' },

            ambiguous_runtime: { code: 422_400_6, message: 'Runtime could not be identified, there are multiple '\
                "matches for '%s': %s" },

            invalid_runtime: { code: 422_400_7, message: "Invalid runtime, could not identify cartridge for '%s'." }
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
