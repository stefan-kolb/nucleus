module Paasal
  # The {Adapters} module combines all application logic to communicate with the different vendor platforms
  # and created the unified API.
  module Adapters
    # The {BaseAdapter} is an abstract class that shall be extended by all actual Adapters.
    # It provides methods to common functionality:<br>
    # * authentication (+cache)
    # * http client with general error handling
    # * native platform API calls
    # @abstract
    class BaseAdapter
      include HttpClient
      include HttpTailClient
      include Logging

      attr_reader :endpoint_url

      def initialize(endpoint_url, endpoint_app_domain = nil, check_certificates = true)
        fail ArgumentError, "'endpoint_url' must be a valid URL" unless endpoint_url =~ /\A#{URI.regexp(['https'])}\z/
        @endpoint_url = endpoint_url
        @endpoint_app_domain = endpoint_app_domain
        @check_certificates = check_certificates
      end

      # thread-based cache for the api authorization headers
      thread_config_accessor :auth_objects_cache, default: {}

      # Cache the auth information.
      # @param [String] key cache key
      # @param [Paasal::Adapters::AuthClient] auth_object authentication client to be cached
      # @return [void]
      def cache(key, auth_object)
        auth_objects_cache[key] = auth_object
      end

      # Are there cached information for this key?
      # @param [String] key cache key
      # @return [true, false] true if has cached auth info, else false
      def cache?(key)
        auth_objects_cache.key? key
      end

      # Get the currently cached authentication object.
      # @param [String] key cache key
      # @return [Hash<String,String>, Paasal::Adapters::AuthClient] cached authentication client
      def cached(key)
        return nil unless cache?(key)
        auth_objects_cache[key]
      end

      # Create the cache key for the username / password combination and save it in the {::RequestStore} to make it
      # available throughout the current request.
      # @param [String] username the username for the authentication
      # @param [String] password the password for the authentication
      # @return [String] calculated hash key for the input values
      def cache_key(username, password)
        # calculate the cache only once per request
        return RequestStore.store[:cache_key] if RequestStore.exist?(:cache_key)
        key = Digest::SHA256.hexdigest "#{endpoint_url}#{username}:#{password}"
        RequestStore.store[:cache_key] = key
        key
      end

      # Get the cached authentication object and retrieve the presumably valid authentication header.
      # @return [Hash<String,String>] hash including a valid authentication header
      def headers
        auth_object = auth_objects_cache[RequestStore.store[:cache_key]]
        # AuthClient, generates the header for us
        auth_object.auth_header
      end

      # Execute an API call, targeted directly against the vendors API.
      # @param [Symbol] method http method to use, one of: [:GET, :POST, :DELETE, :PUT, :PATCH]
      # @param [String] path url path to append to the endpoint's URL
      # @param [Hash] params body params to use for PATCH, :PUT and :POST requests
      # @return [Object] the actual response body of the vendor platform
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

      # Fail with a {Errors::PlatformSpecificSemanticError} error and format the error message to include the values
      # that are passed in the params. Requires the adapter to provide a +semantic_error_messages+ method, which shall
      # return a Hash with the platform specific semantic errors.
      # @param [Symbol] error_name error that shall be returned
      # @param [Array<String>] params values that are to be included in the error message template
      # @raise [Errors::PlatformSpecificSemanticError]
      def fail_with(error_name, params = nil)
        unless respond_to?(:semantic_error_messages)
          fail StandardError 'Invalid adapter implementation, no :semantic_error_messages method provided'
        end
        error = semantic_error_messages[error_name]
        fail Errors::PlatformSpecificSemanticError.new(error[:message] % params, error[:code])
      end
    end
  end
end
