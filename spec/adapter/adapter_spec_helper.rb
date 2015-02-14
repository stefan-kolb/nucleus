require 'airborne'
require 'scripts/initialize_core'
require 'scripts/initialize_rack'
require 'spec/spec_helper'
require 'spec/support/shared_example_request_types'
require 'spec/adapter/credentials_helper'
require 'spec/adapter/adapter_helper'
require 'spec/adapter/support/shared_example_adapters'

# define (override from integration) test suite for coverage report
SimpleCov.command_name 'spec:suite:adapters'

Airborne.configure do |config|
  config.rack_app = Paasal::Rack.app
  config.headers = { 'HTTP_ACCEPT' => 'application/vnd.paasal-v1' }
end

def load_adapter(endpoint_id, api_version)
  Paasal::Spec::Config::AdapterHelper.instance.load_adapter(endpoint_id, api_version)
end

def credentials(endpoint_id, valid = true)
  return Paasal::Spec::Config.credentials.valid endpoint_id if valid
  Paasal::Spec::Config.credentials.invalid
end

def username_password(endpoint_id)
  Paasal::Spec::Config.credentials.username_password endpoint_id
end

def vcr_record_mode
  (ENV['VCR_RECORD_MODE'] || :none).to_sym
end

################
# RSPEC CONFIG #
################

RSpec.configure do |config|
  vcr_cassette_name_for = lambda do |meta|
    description = meta[:description]
    example_group = meta.key?(:example_group) ? meta[:example_group] : meta[:parent_example_group]
    return [vcr_cassette_name_for[example_group], description].join('/') if example_group
    # modify adapter name and split by API version
    description.gsub(/Paasal::Adapters::/, '').underscore.downcase.gsub(/_adapter/, '')
  end

  config.before(:suite) do
    # do a full application start, load entities and put them into the db stores
    Paasal::AdapterImporter.new.import
    Excon.defaults[:mock] = false
  end

  config.after(:suite) do
    FileUtils.rm_rf(configatron.db.path) if File.exist?(configatron.db.path) && File.directory?(configatron.db.path)
  end

  config.before(:each) do |test|
    # clear authentication cache
    Paasal::Adapters::BaseAdapter.auth_objects_cache.clear

    example = test.respond_to?(:metadata) ? test : test.example
    cassette_name = vcr_cassette_name_for[example.metadata]

    # Use complete request to raise errors and require new cassettes as soon as the request changes (!)
    # Use exclusive option to prevent accidental matching requests in different application states
    VCR.insert_cassette(cassette_name, exclusive: true,
                        allow_unused_http_interactions: false,
                        match_requests_on: [:method, :uri_no_auth, :body, :headers_no_auth],
                        decode_compressed_response: true)
  end

  config.after(:each) do |test|
    example = test.respond_to?(:metadata) ? test : test.example
    VCR.eject_cassette(skip_no_unused_interactions_assertion: !example.exception.nil?)
  end
end

########################
# VCR CONFIG & FILTERS #
########################

VCR.configure do |c|
  # save cassettes here
  c.cassette_library_dir = File.join(File.dirname(__FILE__), 'vcr_cassettes')
  # Hooks into: Net::HTTP, HTTPClient, Patron, Curb (Curl::Easy, but not Curl::Multi) EM HTTP Request,
  # Typhoeus (Typhoeus::Hydra, but not Typhoeus::Easy or Typhoeus::Multi) and Excon
  c.hook_into :webmock
  c.hook_into :excon
  c.ignore_localhost = false
  # record once, but do not make updates
  c.default_cassette_options = { record: vcr_record_mode }

  def filter_header(vcr_config, key)
    vcr_config.filter_sensitive_data("__#{key.underscore.upcase}__") do |i|
      if i.request.headers.key? key
        # vcr normalizes header values to arrays
        i.request.headers[key][0]
      else
        "NO_#{key.underscore.upcase}_HEADER_TO_REPLACE_AS_OF_#{DateTime.now}"
      end
    end
  end

  def filter_query(vcr_config, key)
    vcr_config.filter_sensitive_data("__#{key.underscore.upcase}__") do |i|
      query = Rack::Utils.parse_query URI(i.request.uri).query
      if query.key? key
        query[key]
      else
        "NO_#{key.underscore.upcase}_QUERY_TO_REPLACE_AS_OF_#{DateTime.now}"
      end
    end
  end

  def filter_body(body, key, type)
    if body.key? key
      if body[key].is_a?(Array) || body[key].is_a?(Hash)
        body[key].to_json
      else
        body[key]
      end
    else
      "NO_#{key.underscore.upcase}_#{type}_BODY_TO_REPLACE_AS_OF_#{DateTime.now}"
    end
  end

  def filter_response_body(vcr_config, key)
    vcr_config.filter_sensitive_data("__#{key.underscore.upcase}__") do |i|
      response_body = i.response.body.nil? || i.response.body.empty? ? {} : MultiJson.load(i.response.body)
      if response_body.is_a? Array
        replacements = response_body.collect { |entry| filter_body(entry, key, 'RESPONSE') }
        replacements.each_with_index do |replace, index|
          # replace sensitive value of the nested element
          vcr_config.filter_sensitive_data("\"__#{key.underscore.upcase}_#{index}__\"") { |_i| replace }
        end
        # fake replacement, value shall not exist
        "NO_ARRAY_BODY_TO_REPLACE_AS_OF_#{DateTime.now}"
      else
        filter_body(response_body, key, 'RESPONSE')
      end
    end
  end

  def filter_request_body(vcr_config, key)
    vcr_config.filter_sensitive_data("__#{key.underscore.upcase}__") do |i|
      request_body = i.request.body.nil? || i.request.body.empty? ? {} : MultiJson.load(i.request.body)
      if request_body.is_a? Array
        request_body.each { |entry| filter_body(entry, key, 'REQUEST') }
      else
        filter_body(request_body, key, 'REQUEST')
      end
    end
  end

  %w(token).each { |key| filter_query(c, key) }
  %w(Authorization).each { |key| filter_header(c, key) }
  %w(api_key refresh_token access_token).each do |key|
    filter_request_body(c, key)
    filter_response_body(c, key)
  end

  c.register_request_matcher :headers_no_auth do |request_1, request_2|
    # Anonymize header authentication
    headers_1 = request_1.headers
    headers_1['Authorization'] = '__AUTHORIZATION__' if headers_1.key?('Authorization')
    headers_2 = request_2.headers
    headers_2['Authorization'] = '__AUTHORIZATION__' if headers_2.key?('Authorization')
    # finally, compare headers
    headers_1 == headers_2
  end

  c.register_request_matcher :uri_no_auth do |request_1, request_2|
    uri_1 =  URI(request_1.uri)
    uri_2 =  URI(request_2.uri)
    query_1 = Rack::Utils.parse_query uri_1.query
    query_2 = Rack::Utils.parse_query uri_2.query

    %w(username user password token).each do |key|
      query_1[key] = "__#{key.upcase}__" if query_1.key?(key)
      query_2[key] = "__#{key.upcase}__" if query_2.key?(key)
    end

    valid = query_1 == query_2
    valid &&= uri_1.scheme == uri_2.scheme
    valid &&= uri_1.userinfo == uri_2.userinfo
    valid &&= uri_1.host == uri_2.host
    valid &&= uri_1.port == uri_2.port
    valid &&= uri_1.fragment == uri_2.fragment
    valid
  end

  # filter heroku user identification
  c.filter_sensitive_data('__USER_ID__@users.heroku.com') do |i|
    response_body = i.response.body.nil? || i.response.body.empty? ? {} : MultiJson.load(i.response.body)
    if response_body.is_a?(Hash) && /^\S+@users.heroku.com$/ =~ response_body['id']
      response_body['id']
    else
      "NO_HEROKU_USER_ID_IN_RESPONSE_BODY_TO_REPLACE_AS_OF_#{DateTime.now}"
    end
  end

  # filter all sensitive data stored in the credentials config
  Paasal::Spec::Config.credentials.sensitive_data.each do |replacement, replace|
    c.filter_sensitive_data("__#{replacement}__") { |_i| replace }
  end

  # log VCR interactions
  # c.debug_logger = File.open('log/vcr.log', 'w')
end
