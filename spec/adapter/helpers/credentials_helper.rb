require 'base64'
require 'singleton'
require 'vcr'

module Nucleus
  module Spec
    module Config
      class CredentialsHelper
        include Singleton

        def initialize
          # block is executed each time a key is not-present
          @hash = Hash.new do |hash, adapter|
            # TODO: this would only happen for a mixed string symbol hash, do we really need this?
            if hash.key?(adapter.to_s)
              hash[adapter] = hash[adapter.to_s]
            else
              # raise error if recording and no credentials are found
              raise StandardError, "No credentials found for #{adapter}" if vcr_recording?

              hash[adapter] = {
                'user' => 'faked_user',
                'password' => 'faked_password',
                'endpoint' => 'faked_endpoint'
              }
            end
          end
          begin
            fname = ENV['CONFIG'] || File.expand_path('config/.credentials')
            @hash.merge!(YAML.safe_load(File.open(fname)))
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

        # Get all sensitive credential values
        # @return[Hash<String,Hash<String, String>>] hash of endpoint_ids with sensitive key value pairs
        def sensitive_data
          @hash
        end

        private

        def to_auth_header(username, password)
          # we must use the already translated header, ready for use in the Rack env
          { 'HTTP_AUTHORIZATION' => 'Basic ' + Base64.strict_encode64("#{username}:#{password}") }
        end

        def vcr_recording?
          VCR.current_cassette && VCR.current_cassette.recording?
        end
      end

      # Get the spec credential configuration
      # @return [Nucleus::Spec::Config::CredentialsHelper] Instance of the CredentialsHelper
      def self.credentials
        CredentialsHelper.instance
      end
    end
  end
end
