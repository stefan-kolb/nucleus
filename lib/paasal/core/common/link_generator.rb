module Paasal
  class LinkGenerator
    def initialize(env, api_version)
      @env = env
      @version = api_version
    end

    # Generate the link that references the resource.
    # @param [Array<String>] namespaces nested namespaces that must be joined to access the resource
    # @param [String] id id of the resource
    # @return [String] URL to the resource
    def resource(namespaces, id)
      # resource can only exist for an API version
      link = api_root
      # combine namespace and entity ID
      link << namespace(namespaces)
      link << "/#{id}" unless id.nil? || id.empty?
      # return the created link
      link
    end

    # Create a link to the API root node.
    #
    # @return [String] link to the API root
    def api_root
      root_url << '/api'
    end

    # Get the root URL of the Paasal API (scheme + host)
    def root_url
      "#{@env['rack.url_scheme']}://#{@env['HTTP_HOST']}"
    end

    private

    def namespace(namespaces)
      if namespaces.is_a?(String) && !namespaces.empty?
        "/#{namespaces}"
      elsif !namespaces.nil? && !namespaces.empty?
        "/#{namespaces.join('/')}"
      else
        ''
      end
    end
  end
end
