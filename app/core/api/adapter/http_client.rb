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
        # log.debug("#{params[:method]} --> #{url}")
        response = Excon.new(url, excon_connection_params).request(add_common_request_params(params))
        # log.debug("Response received for request to #{url}")
        # we never want the JSON string, but always the hash representation
        response.body = hash_of(response.body)
        response
      rescue Excon::Errors::HTTPStatusError => e
        handle_execute_request_error(e, url)
      end

      def handle_execute_request_error(e, url)
        log.debug 'ERROR, Excon could not execute the request.'
        # transform json response to Hash object
        e.response.body = hash_of(e.response.body)
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
          fail Errors::AuthenticationError, 'Auth. failed, probably cache is outdated or permissions were revoked?'
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

      def excon_connection_params
        middleware = Excon.defaults[:middlewares].dup
        middleware << Excon::Middleware::Decompress
        middleware << Excon::Middleware::RedirectFollower
        { middlewares: middleware, ssl_verify_peer: @check_certificates }
      end

      def hash_of(message_body)
        return {} if message_body.nil? || message_body.empty?
        begin
          return MultiJson.load(message_body, symbolize_keys: true)
        rescue MultiJson::ParseError
          # parsing failed, content probably is no valid JSON content
          message_body
        end
      end

      def add_common_request_params(params)
        common_params = { connection_timeout: 600, write_timeout: 300, read_timeout: 90 }
        # allow to follow redirects in the APIs
        params[:expects] = [301, 302, 303, 307, 308].push(*params[:expects]).uniq
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
