module Nucleus
  module API
    module Models
      # The AbstractEntity is designed as super-class for all entities that shall be exposed via the API.
      # For exposing the data we use the Grape::Entity class.
      # To simplify the link creation, the class provides multiple *link_* methods.
      class AbstractEntity < Grape::Entity
        # Create a link to a resource representation.
        # If no parameters are provided, a link to the API root is returned.
        #
        # @param [Array<String>] namespaces path to the resource, e.g. %w(vendors xyc providers)
        # @param [Hash, String] instance_or_id status object of the proc block, or directly the ID
        #
        # @return [String] link to a resource of the API
        def link_resource(namespaces = nil, instance_or_id = nil)
          namespaces = [] if namespaces.nil?
          id = ''
          if instance_or_id.respond_to?('id')
            id = instance_or_id.id unless instance_or_id.id.nil?
          elsif instance_or_id.is_a? String
            id = instance_or_id
          end
          link_generator.resource(namespaces, id)
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
          link << "/#{child_namespaces.join('/')}" unless child_namespaces.nil? || child_namespaces.empty?
          # return the created link
          link
        end

        # Create a link to the documentation.
        # @return [String] link to the API or API version documentation
        def link_docs
          "#{link_generator.root_url}/docs"
        end

        # Create a link to the current API version.
        # The version is determined either from the current request path, or from the current object.
        #
        # @return [String] link to the current API version
        def link_api_version
          # link_generator.api_version
          link_api_root
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

        def link_generator
          return @link_generator unless @link_generator.nil?
          # Create a new generator instance
          if is_a?(ApiVersion)
            version = object[:name]
          elsif !options[:version].nil?
            version = options[:version]
          end
          @link_generator = Nucleus::LinkGenerator.new(options[:env], version)
          @link_generator
        end
      end
    end
  end
end
