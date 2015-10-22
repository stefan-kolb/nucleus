module Nucleus
  module API
    module FormProcessingHelper
      extend Grape::API::Helpers

      def update_fields(entity, entity_documentation, fields)
        # update all fields, but only with allowed values (according to the doc)
        fields.each do |key, value|
          # only continue if the value can be assigned to the entity
          next unless entity.respond_to? key
          allow_blank = entity_documentation[key.to_sym][:allow_blank]
          # allow_nil = entity_documentation[key][:required]

          unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
            # currently no nil values allowed
            next if value.nil?
            # if value is blank, blank must be allowed
            next if value.empty? && !allow_blank
          end
          # finally update the value
          entity.send("#{key}=", value)
        end unless fields.nil?
      end
    end
  end
end
