module Nucleus
  module Adapters
    module HttpTailClient
      # Executes a request to the given URL and expects a streaming response.<br>
      # Each new chunk (usually lines) will be forwarded to the client via the api_stream.
      #
      # @param [String] url url to call
      # @param [Nucleus::API::StreamCallback] api_stream stream to which new chunks will be forwarded
      # @param [Symbol] http_method HTTP method to use
      def tail_http_response(url, api_stream, http_method = :get)
        http_connection = EventMachine::HttpRequest.new(url, inactivity_timeout: 0)
        http_client = http_connection.send(http_method, keepalive: true)

        # close stream on error
        http_client.on_error do
          log.debug('HttpTailClient detected an error, close stream...')
          api_stream.close
        end
        # tail and immediately push the results to the stream
        http_client.stream { |chunk| api_stream.send_message(chunk) }
        # return object that responds to :stop and cancels the tailing request
        TailStopper.new(http_connection, :close)
      end
    end
  end
end
