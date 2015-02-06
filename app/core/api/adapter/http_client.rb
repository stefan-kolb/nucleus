module Paasal
  module Adapters
    module HttpClient
      # Executes a GET request to the given URL.
      #
      # @param [String] path path to add to the endpoint URL
      # @param [Hash] params options to call the post request with
      # @option params [Array<int>] :expects ([200]) http status code that is expected
      # @option params [Hash] :headers request headers to use with the request
      # @raise [Paasal::Errors::ApiError] if the call failed and did not return the expected code(s)
      def get(path, params = {})
        # idempotent: true, retry_limit: 2
        params[:expects] = [200] unless params.key? :expects
        params[:method] = :get
        execute_request(path, params)
      end

      # Executes a POST request to the given URL.
      #
      # @param [String] path path to add to the endpoint URL
      # @param [Hash] params options to call the post request with
      # @option params [Array<int>] :expects ([200,201]) http status code that is expected
      # @option params [Hash] :body request body, will be converted to json format
      # @option params [Hash] :headers request headers to use with the request
      # @raise [Paasal::Errors::ApiError] if the call failed and did not return the expected code(s)
      def post(path, params = {})
        params[:expects] = [200, 201] unless params.key? :expects
        params[:method] = :post
        execute_request(path, params)
      end

      # Executes a PATCH request to the given URL.
      #
      # @param [String] path path to add to the endpoint URL
      # @param [Hash] params options to call the post request with
      # @option params [Array<int>] :expects ([200,201]) http status code that is expected
      # @option params [Hash] :body request body, will be converted to json format
      # @option params [Hash] :headers request headers to use with the request
      # @raise [Paasal::Errors::ApiError] if the call failed and did not return the expected code(s)
      def patch(path, params = {})
        params[:expects] = [200, 201] unless params.key? :expects
        params[:method] = :patch
        execute_request(path, params)
      end

      # Executes a PUT request to the given URL.
      #
      # @param [String] path path to add to the endpoint URL
      # @param [Hash] params options to call the post request with
      # @option params [Array<int>] :expects ([200,201]) http status code that is expected
      # @option params [Hash] :body request body, will be converted to json format
      # @option params [Hash] :headers request headers to use with the request
      # @raise [Paasal::Errors::ApiError] if the call failed and did not return the expected code(s)
      def put(path, params = {})
        params[:expects] = [200, 201] unless params.key? :expects
        params[:method] = :put
        execute_request(path, params)
      end

      # Executes a DELETE request to the given URL.
      #
      # @param [String] path path to add to the endpoint URL
      # @param [Hash] params options to call the post request with
      # @option params [Array<int>] :expects ([200,204]) http status code that is expected
      # @option params [Hash] :headers request headers to use with the request
      # @raise [Paasal::Errors::ApiError] if the call failed and did not return the expected code(s)
      def delete(path, params = {})
        params[:expects] = [200, 204] unless params.key? :expects
        params[:method] = :delete
        execute_request(path, params)
      end

      private

      def execute_request(path, params)
        url = to_url path
        # allow to follow redirects in the APIs
        # params[:expects] = [301, 302, 303, 307, 308].push(*params[:expects]).uniq
        params[:headers] = headers
        params[:body] = params[:body].to_json if params.key? :body
        request_params = common_request_params.merge(params)

        response = Excon.new(url, excon_connection_params).request(request_params)
        log.debug("Response received for request to #{url}")
        # we never want the JSON string, but always the hash representation
        response.body = hash_of(decompress(response).body)
        response
      rescue Excon::Errors::HTTPStatusError => e
        log.debug 'ERROR, Excon could not execute the request.'
        e.response.body = hash_of(e.response.body)

        if respond_to? :handle_error
          handle_error(e.response)
        end

        # arriving here, error could not be processed --> use fallback errors
        if e.is_a? Excon::Errors::ServerError
          raise Errors::UnknownAdapterCallError.new(e.message, API::ErrorMessages::RESCUED_ADAPTER_CALL_SERVER)
        elsif e.response.status == 404
          log.error("Resource not found (404) at '#{url}', indicating an adapter issue")
          raise Errors::UnknownAdapterCallError.new('Resource not found, probably the adapter must be updated')
        elsif e.response.status == 401
          raise Errors::AuthenticationError, 'Auth. failed, probably cache is outdated or permissions were revoked?'
        else
          log.error("Fallback error handling (#{e.response.status}) at '#{url}', indicating an adapter issue")
          raise Errors::UnknownAdapterCallError, e.message
        end
      end

      def to_url(path)
        # insert missing slash, prevent double slashes
        return "#{@endpoint_url}/#{path}" unless @endpoint_url.end_with?('/') || path.start_with?('/')
        "#{@endpoint_url}#{path}"
      end

      def excon_connection_params
        middleware = Excon.defaults[:middlewares].dup
        middleware << Excon::Middleware::Decompress
        # middleware << Excon::Middleware::RedirectFollower
        { middlewares: middleware, ssl_verify_peer: @check_certificates }
      end

      def hash_of(message_body)
        return {} if message_body.nil? || message_body.empty?
        MultiJson.load(message_body, symbolize_keys: true)
      end

      def decompress(response)
        return response unless response.headers['Content-Encoding'] == 'gzip'
        response.body = Zlib::GzipReader.new(StringIO.new(response.body)).read
        response
      end

      def common_request_params
        { connection_timeout: 600, write_timeout: 300, read_timeout: 90 }
      end
    end
  end
end
