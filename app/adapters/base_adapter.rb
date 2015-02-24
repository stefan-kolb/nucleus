module Paasal
  module Adapters
    class BaseAdapter
      include Paasal::Adapters::HttpClient
      include Paasal::Logging

      def initialize(endpoint_url, check_certificates = true)
        fail ArgumentError, "'endpoint_url' must be a valid URL" unless endpoint_url =~ /\A#{URI.regexp(['https'])}\z/
        @endpoint_url = endpoint_url
        @check_certificates = check_certificates
      end

      # Get a OAuth2 client for this URL.
      # @return [Paasal::OAuth2Client] OAuth2Client instance to handle the authentication
      def oauth2(auth_url)
        Paasal::OAuth2Client.new(auth_url, @check_certificates)
      end

      # thread-based cache for the api authorization headers
      thread_config_accessor :auth_objects_cache, default: {}

      # Cache the auth information.
      # @param [String] username username for cache key
      # @param [String] password password for cache key
      # @param [Hash<String,String>, Paasal::OAuth2Client] auth_object auth information to be cached
      # @return [void]
      def cache(username, password, auth_object)
        key = cache_key(username, password)
        auth_objects_cache[key] = auth_object
      end

      # Evict the cache for this cache key.
      # @param [String] key cache to evict
      def uncache(key)
        auth_objects_cache.delete key
      end

      # Are there cached information for the current user?
      # @param [String] username username for cache lookup
      # @param [String] password password for cache lookup
      # @return [true, false] true if has cached auth info, else false
      def cache?(username, password)
        auth_objects_cache.key? cache_key(username, password)
      end

      # Get the cached authentication object, being either the OAuth2Client or the Authorization header.
      # @return [Hash<String,String>, Paasal::OAuth2Client] cached authentication information
      def headers
        auth_object = auth_objects_cache[RequestStore.store[:cache_key]]
        return auth_object if auth_object.is_a? Hash
        # oauth client, generates the header for us
        auth_object.auth_header
      end

      # TODO: documentation
      def endpoint_call(method, path, params)
        case method
        when :GET
          get(path, native_call: true).body
        when :POST
          post(path, native_call: true, body: params).body
        when :DELETE
          delete(path, native_call: true).body
        when :PUT
          put(path, native_call: true, body: params).body
        when :PATCH
          patch(path, native_call: true, body: params).body
        else
          fail AdapterRequestError, 'Unsupported adapter call method. Allowed are: GET, POST, PATCH, PUT, DELETE'
        end
      end

      private

      def cache_key(username, password)
        # calculate the cache only once per request
        return RequestStore.store[:cache_key] if RequestStore.exist?(:cache_key)
        key = Digest::SHA256.hexdigest "#{@endpoint_url}#{username}:#{password}"
        RequestStore.store[:cache_key] = key
        key
      end

      # def self.method_added(name)
      #   return if @__last_methods_added && @__last_methods_added.include?(name)
      #   with_wrapper = :"#{name}_with_before_each_method_call"
      #   without_wrapper = :"#{name}_without_before_each_method_call"
      #   @__last_methods_added = [name, with_wrapper, without_wrapper]
      #   # wrap the method call
      #   define_method with_wrapper do |*args, &block|
      #     log.debug "Calling adapter method '#{name}' against #{@endpoint_url}"
      #     start_time = Time.now
      #     response = send without_wrapper, *args, &block
      #     end_time = Time.now
      #     log.debug "Finished '#{name}' adapter method call against #{@endpoint_url}, took #{end_time - start_time}"
      #     return response
      #   end
      #   alias_method without_wrapper, name
      #   alias_method name, with_wrapper
      #   @__last_methods_added = nil
      # end
    end
  end
end
