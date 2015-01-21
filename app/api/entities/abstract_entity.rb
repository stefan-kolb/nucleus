module Paasal
  module API
    module Models
      # The AbstractEntity is designed as super-class for all entities that shall be exposed via the API.
      # For exposing the data we use {Grape::Entity the Grape::Entity class}.
      # Each entity has to expose a unique ID and a link to the entity's resource itself.
      # To simplify the link creation, the class provides the {#create_link create_link method}.
      class AbstractEntity < Grape::Entity
        # Create a link to a resource representation.
        # If no parameters are provided, a link to the API root is returned.
        #
        # @param [Array<String>] namespaces path to the resource, e.g. %w(vendors xyc providers)
        # @param [Hash, String] instance_or_id status object of the proc block, or directly the ID
        #
        # @return [String] link to a resource of the API
        def link_resource(namespaces = nil, instance_or_id = nil)
          link = link_api_version
          # resource can only exist for an API version
          unless namespaces.nil?
            link << "/#{namespaces.join('/')}"
            # IDs can only be assigned to resource links
            if instance_or_id.respond_to?('id')
              link << "/#{instance_or_id.id}" unless instance_or_id.id.nil?
            elsif instance_or_id.kind_of? String
              link << "/#{instance_or_id}" unless instance_or_id.nil?
            end
          end
          # return the created link
          link
        end

        # Create a link to a child-resource representation.
        # The params will be concatenated in the form
        #     ROOT/{namespaces}/{instance_id}/{child_namespaces}
        #
        # @param [Array<String>] namespaces path to the resource, e.g. %w(vendors xyc providers)
        # @param [Hash, String] instance_or_id status object of the proc block, or directly the ID
        # @param [Array<String>] child_namespaces path to the child-resource that are appended
        # to the instance, e.g. %w(endpoints)
        #
        # @return [String] link to a child resource
        def link_child_resource(namespaces, instance_or_id, child_namespaces)
          # current path as base
          link = link_resource(namespaces, instance_or_id)
          # resource can only exist for an API version
          unless child_namespaces.nil? || child_namespaces.empty?
            link << "/#{child_namespaces.join('/')}"
          end
          # return the created link
          link
        end

        # Create a link to the documentation.
        # If the current object is the root node, the general documentation will be returned.
        # If the current object is an API version, the documentation for this version will be returned.
        #
        # @return [String] link to the API or API version documentation
        def link_docs
          if self.is_a?(ApiVersion)
            "#{root_url}/docs/api/#{object[:name]}"
          else
            "#{root_url}/docs"
          end
        end

        # Create a link to the current API version.
        # The version is determined either from the current request path, or from the current object.
        #
        # @return [String] link to the current API version
        def link_api_version
          link = link_api_root
          if self.is_a?(ApiVersion)
            link << "/#{object[:name]}"
          elsif !options[:version].nil?
            link << "/#{options[:version]}"
          end
          link
        end

        # Create a link to the API root node.
        #
        # @return [String] link to the API root
        def link_api_root
          "#{root_url}/api"
        end

        private

        def root_url
          "#{options[:env]['rack.url_scheme']}://#{options[:env]['HTTP_HOST']}"
        end
      end
    end
  end
end
