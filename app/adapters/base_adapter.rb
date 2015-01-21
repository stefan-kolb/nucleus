require 'digest'

module Paasal
  module Adapters
    class BaseAdapter
      include Paasal::Logging

      # thread-based cache for the api authorization headers
      thread_config_accessor :auth_headers_cache, :default => {}

      def initialize(endpoint_url)
        @endpoint_url = endpoint_url
      end

      def cache(username, password, header)
        key = cache_key(username, password)
        auth_headers_cache[key] = header
      end

      def cached_headers
        auth_headers_cache[RequestStore.store[:cache_key]]
      end

      def uncache(key)
        auth_headers_cache.delete key
      end

      def cache?(username, password)
        auth_headers_cache.key? cache_key(username, password)
      end

      # def self.method_added(name)
      #   return if @__last_methods_added && @__last_methods_added.include?(name)
      #   with_wrapper = :"#{name}_with_before_each_method_call"
      #   without_wrapper = :"#{name}_without_before_each_method_call"
      #   @__last_methods_added = [name, with_wrapper, without_wrapper]
      #   # wrap the method call
      #   define_method with_wrapper do |*args, &block|
      #     log.debug "Calling adapter method '#{name}' against #{@endpoint_url}"
      #     response = send without_wrapper, *args, &block
      #     log.debug "Finished '#{name}' adapter method call against #{@endpoint_url}"
      #     return response
      #   end
      #   alias_method without_wrapper, name
      #   alias_method name, with_wrapper
      #   @__last_methods_added = nil
      # end

      private

      def cache_key(username, password)
        # calculate the cache only once per request
        return RequestStore.store[:cache_key] if RequestStore.exist?(:cache_key)
        key = Digest::SHA256.hexdigest "#{@endpoint_url}#{username}:#{password}"
        RequestStore.store[:cache_key] = key
        key
      end

    end
  end
end
