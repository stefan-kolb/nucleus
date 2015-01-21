module Paasal
  module Adapters
    class HerokuAdapter < Paasal::Adapters::BaseAdapter
      include Paasal::Logging

      # TODO how to assert that the class implements all required operations?
      def initialize(endpoint_url)
        super(endpoint_url)
      end

      # Get access to the required authentication headers via:
      # RequestStore.store[:adapter].cached_headers

      def start
        log.debug "Start @ #{@endpoint_url}"
        raise Errors::InvalidAuthenticationHeaderError, 'test error'
      end

      def stop
        log.debug "Stop @ #{@endpoint_url}"
      end

      def restart
        log.debug "Restart @ #{@endpoint_url}"
      end

      def applications
        p headers
        response = Excon.get("#{@endpoint_url}/apps", headers: headers)
        response_parsed = JSON.parse(response.body, symbolize_names: true)
        # TODO convert to compliant Hash
        response_parsed
      end

      def authenticate(username, password)
        log.debug "Authenticate @ #{@endpoint_url}"
        # TODO share the connection
        response = Excon.post("#{@endpoint_url}/login?username=#{username}&password=#{password}")

        # Heroku returns 404 for invalid credentials
        # TODO customize the error, include proper dev message
        raise Errors::AuthenticationFailedError, 'Heroku says the credentials are invalid' if response.status == 404

        response_parsed = JSON.parse(response.body)
        api_token = response_parsed['api_key']
        # finally return the header key and value
        { 'Authorization' => "Bearer #{api_token}"}
      end

      # Excon.get('http://geemus.com', :headers => {'Authorization' => 'Basic 0123456789ABCDEF'})
      # connection.get(:headers => {'Authorization' => 'Basic 0123456789ABCDEF'})

      private

      def headers
        {
            'Accept' => 'application/vnd.heroku+json; version=3',
            'Content-Type' => 'application/json',
        }.merge(RequestStore.store[:adapter].cached_headers)
      end

    end
  end
end