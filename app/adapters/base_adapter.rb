require 'digest'

module Paasal
  module Adapters
    class BaseAdapter
      include Paasal::Logging

      # thread-based cache for the api authorization headers
      thread_config_accessor :auth_objects_cache, default: {}

      def initialize(endpoint_url, check_certificates = true)
        fail ArgumentError, "'endpoint_url' must be a valid URL" unless endpoint_url =~ /\A#{URI::regexp(['https'])}\z/
        @endpoint_url = endpoint_url
        @check_certificates = check_certificates
      end

      def cache(username, password, auth_object)
        key = cache_key(username, password)
        auth_objects_cache[key] = auth_object
      end

      def headers
        auth_object = auth_objects_cache[RequestStore.store[:cache_key]]
        return auth_object unless auth_object.is_a? Paasal::OAuth2Client
        # oauth client, generates the header for us
        auth_object.auth_header
      end

      def uncache(key)
        auth_objects_cache.delete key
      end

      def cache?(username, password)
        auth_objects_cache.key? cache_key(username, password)
      end

      def oauth2(auth_url)
        Paasal::OAuth2Client.new(auth_url, @check_certificates)
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
