module Rack
  class MockSession
    def request(uri, env)
      env['HTTP_COOKIE'] ||= cookie_jar.for(uri)
      @last_request = Rack::Request.new(env)
      status, headers, body = @app.call(@last_request.env)

      # this patch is tailored to rack-test version v0.6.3
      body = merge_chunks(body, headers)

      @last_response = MockResponse.new(status, headers, body, env['rack.errors'].flush)
      body.close if body.respond_to?(:close)

      cookie_jar.merge(last_response.headers['Set-Cookie'], uri)

      @after_request.each(&:call)

      if @last_response.respond_to?(:finish)
        @last_response.finish
      else
        @last_response
      end
    end

    private

    def merge_chunks(body, headers)
      return body unless headers && headers.key?('Transfer-Encoding') && headers['Transfer-Encoding'] == 'chunked'

      processed_body = ''
      body.each do |chunk_line|
        # remove final CRLF
        chunk_size, chunk = chunk_line.chomp.split("\r\n", 2)
        processed_body << chunk if chunk_size.to_i(16) > 0
      end
      processed_body
    end
  end
end
