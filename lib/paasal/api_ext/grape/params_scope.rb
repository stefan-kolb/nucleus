module Grape
  module Validations
    class ParamsScope
      # capture the original grape method, but only during definition, won't be available later on
      old_validates = instance_method(:validates)

      # now define the patched method, which first updates the validators, then calls the original implementation
      define_method(:validates) do |attrs, validations|
        # modify the validations, so that invalid validators are removed
        %w(is_array required example).each do |invalid_validator_name|
          # do not remove if there is a validator matching the documentation name
          unless Grape::Validations.validators[invalid_validator_name.to_s]
            validations.delete(invalid_validator_name.to_sym)
          end
        end

        # call the actual implementation
        old_validates.bind(self).call(attrs, validations)
      end
    end
  end
end
