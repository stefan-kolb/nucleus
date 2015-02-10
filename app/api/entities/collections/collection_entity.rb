module Paasal
  module API
    module Models
      class CollectionEntity < AbstractEntity
        # TODO: document me
        def self.item_collection(key, full_name, model)
          present_collection true
          model_class_name = model.to_s.gsub(/^.*::/, '')

          expose :size, documentation: {
            type: 'int', required_details: { response: true },
            desc: "Number of items in the '#{key}' collection"
          } do |instance, _o|
            instance[:items].nil? ? 0 : instance[:items].size
          end

          expose :items, as: key, documentation: {
            type: model_class_name, desc: "List of #{full_name}", is_array: true,
            required_details: { response: true }
          }, using: model
        end

        # TODO: document me
        def self.basic_links(unformatted_link, action_name)
          expose :_links, using: Models::BasicReferences, documentation: {
            required_details: { response: true },
            type: 'BasicReferences', desc: 'Resource links', is_array: true } do |_instance, o|
            {
              self: { href: link_resource(format(unformatted_link, o[:env]['rack.routing_args']), action_name) },
              # link back to the parent resource
              parent: { href: link_resource(format(unformatted_link, o[:env]['rack.routing_args'])) }
            }
          end
        end
      end
    end
  end
end
