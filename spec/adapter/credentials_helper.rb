require 'singleton'

module Paasal
  module Spec
    module Config
      class CredentialsHelper
        include Singleton

        def initialize
          # block is executed each time a key is not-present

          # TODO: raise error if no credentials are found
          @hash = Hash.new do |hash, adapter|
            if hash.key?(adapter.to_s)
              hash[adapter] = hash[adapter.to_s]
            else
              hash[adapter] = {
                'user' => 'faked_user',
                'password' => 'faked_password',
                'endpoint' => 'faked_endpoint'
              }
            end
          end
          begin
            fname = ENV['CONFIG'] || File.expand_path('config/.credentials')
            @hash.merge!(YAML.load(File.open(fname)))
          rescue Errno::ENOENT
            # Ignore if file was not found
            p "No endpoint credentials configuration found at 'config/.credentials'"
          end
        end

        # Get valid credentials for the current endpoint from
        # the config/.credentials file if found.
        #
        # $ cat config/.credentials
        # heroku:
        #   user:     'myherokuuser'
        #   password: 'myherokuuserpassword'
        # openshift-online:
        #   user: 'myopenshiftuser'
        #   password: 'myopenshiftuserpassword'
        #
        # @param[String] endpoint_id unique id of the endpoint to get credentials for
        # @return[Hash<String,String>] authorization header with valid credentials to the endpoint
        def valid(endpoint_id)
          username, password = username_password(endpoint_id)
          to_auth_header username, password
        end

        # Get invalid credentials.
        # @return[Hash<String,String>] authorization header with invalid credentials
        def invalid
          username = 'an_invalid_username'
          password = 'an_invalid_password'
          to_auth_header username, password
        end

        # Get a valid username and password to the endpoint.
        # @return[Array<String>] array with username at index 0 and password at index 1
        def username_password(endpoint_id)
          [@hash[endpoint_id]['user'], @hash[endpoint_id]['password']]
        end

        # Get all sensitive values that shall not be included in the VCR logs.
        # @return[Hash<String,String>>] key value pairs, key is replacement for the value that shall be replaced
        def sensitive_data
          response = {}
          @hash.each do |endpoint, data|
            data.each do |name, value|
              response["#{endpoint}:#{name}"] = value
            end
          end
          response
        end

        private

        def to_auth_header(username, password)
          # we must use the already translated header, ready for use in the Rack env
          { 'HTTP_AUTHORIZATION' => 'Basic ' + ["#{username}:#{password}"].pack('m*').gsub(/\n/, '') }
        end
      end

      # Get the spec credential configuration
      # @return [Paasal::Spec::Config::CredentialsHelper] Instance of the CredentialsHelper
      def self.credentials
        CredentialsHelper.instance
      end
    end
  end
end
