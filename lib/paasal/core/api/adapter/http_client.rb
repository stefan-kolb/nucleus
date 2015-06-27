module Paasal
  module Adapters
    module HttpClient
      # Executes a HEAD request to the given URL.
      #
      # @param [String] path path to add to the endpoint URL
      # @param [Hash] params options to call the post request with
      # @option params [Array<int>] :expects ([200]) http status code that is expected
      # @option params [Hash] :headers request headers to use with the request
      # @option params [Boolean] :native_call if true the request is a native API call and shall return the
      # unprocessed response
      # @raise [Paasal::Errors::AdapterError] if the call failed and did not return the expected code(s)
      def head(path, params = {})
        execute_request(:head, [200], path, params, params.delete(:native_call) { false })
      end

      # Executes a GET request to the given URL.
      #
      # @param [String] path path to add to the endpoint URL
      # @param [Hash] params options to call the post request with
      # @option params [Array<int>] :expects ([200]) http status code that is expected
      # @option params [Hash] :headers request headers to use with the request
      # @option params [Boolean] :native_call if true the request is a native API call and shall return the
      # unprocessed response
      # @raise [Paasal::Errors::AdapterError] if the call failed and did not return the expected code(s)
      def get(path, params = {})
        execute_request(:get, [200], path, params, params.delete(:native_call) { false })
      end

      # Executes a POST request to the given URL.
      #
      # @param [String] path path to add to the endpoint URL
      # @param [Hash] params options to call the post request with
      # @option params [Array<int>] :expects ([200,201]) http status code that is expected
      # @option params [Hash] :body request body, will be converted to json format
      # @option params [Hash] :headers request headers to use with the request
      # @option params [Boolean] :native_call if true the request is a native API call and shall return the
      # unprocessed response
      # @raise [Paasal::Errors::AdapterError] if the call failed and did not return the expected code(s)
      def post(path, params = {})
        execute_request(:post, [200, 201], path, params, params.delete(:native_call) { false })
      end

      # Executes a PATCH request to the given URL.
      #
      # @param [String] path path to add to the endpoint URL
      # @param [Hash] params options to call the post request with
      # @option params [Array<int>] :expects ([200,201]) http status code that is expected
      # @option params [Hash] :body request body, will be converted to json format
      # @option params [Hash] :headers request headers to use with the request
      # @option params [Boolean] :native_call if true the request is a native API call and shall return the
      # unprocessed response
      # @raise [Paasal::Errors::AdapterError] if the call failed and did not return the expected code(s)
      def patch(path, params = {})
        execute_request(:patch, [200, 201], path, params, params.delete(:native_call) { false })
      end

      # Executes a PUT request to the given URL.
      #
      # @param [String] path path to add to the endpoint URL
      # @param [Hash] params options to call the post request with
      # @option params [Array<int>] :expects ([200,201]) http status code that is expected
      # @option params [Hash] :body request body, will be converted to json format
      # @option params [Hash] :headers request headers to use with the request
      # @option params [Boolean] :native_call if true the request is a native API call and shall return the
      # unprocessed response
      # @raise [Paasal::Errors::AdapterError] if the call failed and did not return the expected code(s)
      def put(path, params = {})
        execute_request(:put, [200, 201], path, params, params.delete(:native_call) { false })
      end

      # Executes a DELETE request to the given URL.
      #
      # @param [String] path path to add to the endpoint URL
      # @param [Hash] params options to call the post request with
      # @option params [Array<int>] :expects ([200,204]) http status code that is expected
      # @option params [Hash] :headers request headers to use with the request
      # @option params [Boolean] :native_call if true the request is a native API call and shall return the
      # unprocessed response
      # @raise [Paasal::Errors::AdapterError] if the call failed and did not return the expected code(s)
      def delete(path, params = {})
        execute_request(:delete, [200, 204], path, params, params.delete(:native_call) { false })
      end

      private

      def execute_request(method, default_expect, path, params, native_call = false)
        params[:expects] = default_expect unless params.key? :expects
        params[:method] = method

        url = Regexp::PERFECT_URL_PATTERN =~ path ? path : to_url(path)
        response = Excon.new(url, excon_connection_params(params)).request(add_common_request_params(params))
        # we never want the JSON string, but always the hash representation
        response.body = hash_of(response.body)
        response
      rescue Excon::Errors::HTTPStatusError => e
        handle_execute_request_error(e, url, native_call)
      end

      def handle_execute_request_error(e, url, native_call)
        log.debug 'ERROR, Excon could not execute the request.'
        # transform json response to Hash object
        e.response.body = hash_of(e.response.body)

        # if this is a native API call, do not further process the error
        return e.response if native_call

        # fail with adapter specific error handling
        handle_error(e.response) if respond_to?(:handle_error)
        fallback_error_handling(e, url)
      end

      def fallback_error_handling(e, url)
        error_status = e.response.status
        # arriving here, error could not be processed --> use fallback errors
        if e.is_a? Excon::Errors::ServerError
          fail Errors::UnknownAdapterCallError, e.message
        elsif error_status == 404
          log.error("Resource not found (404) at '#{url}', indicating an adapter issue")
          fail Errors::UnknownAdapterCallError, 'Resource not found, probably the adapter must be updated'
        elsif error_status == 401
          fail Errors::EndpointAuthenticationError,
               'Auth. failed, probably cache is outdated or permissions were revoked?'
        else
          log.error("Fallback error handling (#{error_status}) at '#{url}', indicating an adapter issue")
          fail Errors::UnknownAdapterCallError, e.message
        end
      end

      def to_url(path)
        # insert missing slash, prevent double slashes
        return "#{@endpoint_url}/#{path}" unless @endpoint_url.end_with?('/') || path.start_with?('/')
        "#{@endpoint_url}#{path}"
      end

      def excon_connection_params(params)
        middleware = Excon.defaults[:middlewares].dup

        if params[:follow_redirects] == false
          middleware = [Excon::Middleware::ResponseParser, Excon::Middleware::Decompress].push(*middleware).uniq
        else
          middleware = [Excon::Middleware::ResponseParser, Excon::Middleware::RedirectFollower,
                        Excon::Middleware::Decompress].push(*middleware).uniq
        end
        { middlewares: middleware, ssl_verify_peer: @check_certificates }
      end

      def hash_of(message_body)
        return {} if message_body.nil? || message_body.empty?
        begin
          return Oj.load(message_body, symbol_keys: true)
        rescue Oj::Error
          # parsing failed, content probably is no valid JSON content
          message_body
        end
      end

      def add_common_request_params(params)
        common_params = { connection_timeout: 610, write_timeout: 600, read_timeout: 600 }
        # allow to follow redirects in the APIs
        allowed_status_codes = params.key?(:expects) ? [*params[:expects]] : []
        unless params[:follow_redirects] == false
          allowed_status_codes.push(*[301, 302, 303, 307, 308])
        end

        params[:expects] = allowed_status_codes.uniq
        # use default or customized headers
        params[:headers] = headers unless params[:headers]
        # specify encoding if not done yet: use only gzip since deflate does cause issues with VCR cassettes in tests
        params[:headers]['Accept-Encoding'] = 'gzip' unless params[:headers].key? 'Accept-Encoding'
        params[:body] = params[:body].to_json if params.key? :body
        # merge and return
        common_params.merge params
      end
    end
  end
end
