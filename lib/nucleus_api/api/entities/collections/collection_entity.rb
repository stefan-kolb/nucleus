module Nucleus
  module API
    module Models
      # The {CollectionEntity} is a Grape::Entity model for API references to match HATEOAS.
      # It is based on the HAL syntax http://stateless.co/hal_specification.html and provides convenience methods
      # to be used by child classes.
      class CollectionEntity < AbstractEntity
        # A collection, for instance applications registered at the endpoint.
        # Exposes the list of items and meta information, e.g. the size of the collection.
        # @param [String] key key to be used in the api as entry
        # @param [String] full_name full name of the entity, used for the collection's description
        # @param [Nucleus::API::Models::AbstractEntity] model class of the entities contained in the collection
        # @return [void]
        def self.item_collection(key, full_name, model)
          present_collection true
          model_class_name = model.to_s.gsub(/^.*::/, '')

          expose :size, documentation: {
            type: 'int', required: true,
            desc: "Number of items in the '#{key}' collection"
          } do |instance, _o|
            instance[:items].nil? ? 0 : instance[:items].size
          end

          expose :items, as: key.to_sym, documentation: {
            type: model_class_name, desc: "List of #{full_name}", is_array: true,
            required: true
          }, using: model
        end

        # Create the basic links for the collection. This includes the self-reference and the parent API element.
        # @param [String] unformatted_link unformatted link of the parent resource
        # @param [String] action_name name of the current action, to be used for self-reference
        # @return [void]
        def self.basic_links(unformatted_link, action_name)
          expose :_links, using: Models::BasicReferences, documentation: {
            required: true,
            type: 'BasicReferences', desc: 'Resource links', is_array: true
          } do |_instance, o|
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
