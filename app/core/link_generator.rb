module Paasal
  class LinkGenerator
    def initialize(env, api_version)
      @env = env
      @version = api_version
    end

    def resource(namespaces, id)
      # resource can only exist for an API version
      link = api_root
      # combine namespace and entity ID
      link << "/#{namespaces.join('/')}" unless namespaces.nil?
      link << "/#{id}" unless id.nil?
      # return the created link
      link
    end

    # # Create a link to the current API version.
    # # The version is determined either from the current request path, or from the current object.
    # #
    # # @return [String] link to the current API version
    # def api_version
    #   api_root << "/#{@version}"
    # end

    # Create a link to the API root node.
    #
    # @return [String] link to the API root
    def api_root
      root_url << '/api'
    end

    # TODO: add documentation
    def root_url
      "#{@env['rack.url_scheme']}://#{@env['HTTP_HOST']}"
    end
  end
end
