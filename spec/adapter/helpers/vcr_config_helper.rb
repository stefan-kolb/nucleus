require 'spec/adapter/helpers/vcr_msgpack_serializer'

########################
# VCR CONFIG & FILTERS #
########################

def vcr_record_mode
  (ENV['VCR_RECORD_MODE'] || :none).to_sym
end

VCR.configure do |c|
  # save cassettes here
  c.cassette_library_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'recordings'))
  # Hooks into: Net::HTTP, HTTPClient, Patron, Curb (Curl::Easy, but not Curl::Multi) EM HTTP Request,
  # Typhoeus (Typhoeus::Hydra, but not Typhoeus::Easy or Typhoeus::Multi) and Excon
  c.hook_into :webmock
  c.hook_into :excon
  c.ignore_localhost = false
  # ignore host as requested by codeclimate
  c.ignore_hosts 'codeclimate.com'
  # record once, but do not make updates
  c.default_cassette_options = { record: vcr_record_mode }

  c.preserve_exact_body_bytes do |http_message|
    http_message.body.encoding.name == 'ASCII-8BIT' || !http_message.body.valid_encoding?
  end

  # custom serializer, which is about x times faster than the default YAML
  c.cassette_serializers[:msgpack] = VCR::Cassette::Serializers::MessagePack

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
      begin
        response_body = i.response.body.nil? || i.response.body.empty? ? {} : MultiJson.load(i.response.body)
        if response_body.is_a? Array
          response_body.collect { |entry| filter_body(entry, key, 'RESPONSE') }.each_with_index do |replace, index|
            # replace sensitive value of the nested element
            vcr_config.filter_sensitive_data("\"__#{key.underscore.upcase}_#{index}__\"") { |_i| replace }
          end
          # fake replacement, value shall not exist
          "NO_ARRAY_BODY_TO_REPLACE_AS_OF_#{DateTime.now}"
        else
          filter_body(response_body, key, 'RESPONSE')
        end
      rescue
        "INVALID_JSON_BODY_AS_OF_#{DateTime.now}"
      end
    end
  end

  def filter_request_body(vcr_config, key)
    vcr_config.filter_sensitive_data("__#{key.underscore.upcase}__") do |i|
      # TODO: skipping multipart / ASCII-8BIT requests for now
      if !multipart?(i) && !i.request.body.encoding.to_s == 'ASCII-8BIT'
        request_body = i.request.body.nil? || i.request.body.empty? ? {} : Oj.load(i.request.body)
        if request_body.is_a? Array
          request_body.each { |entry| filter_body(entry, key, 'REQUEST') }
        else
          filter_body(request_body, key, 'REQUEST')
        end
      else
        "DO_NOT_REPLACE_MULTIPART_AND_BINARY_DATA_AS_OF_#{DateTime.now}"
      end
    end
  end

  def multipart?(i)
    i.request.headers['Content-Type'] && !i.request.headers['Content-Type'][0].start_with?('multipart/form')
  end

  # only filter these fields when we are recording, otherwise the tests take more than 2x as long
  unless vcr_record_mode == :none
    %w(token).each { |key| filter_query(c, key) }
    %w(Authorization).each { |key| filter_header(c, key) }
    %w(api_key token refresh_token access_token).each do |key|
      filter_request_body(c, key)
      filter_response_body(c, key)
    end

    # filter heroku user identification
    c.filter_sensitive_data('__USER_ID__@users.heroku.com') do |i|
      begin
        if i.response.body.nil? || i.response.body.empty?
          "NO_HEROKU_USER_ID_IN_RESPONSE_BODY_TO_REPLACE_AS_OF_#{DateTime.now}"
        else
          response_body = Oj.load(i.response.body)
          response_body['id'] if response_body.is_a?(Hash) && /^\S+@users.heroku.com$/ =~ response_body['id']
        end
      rescue
        "INVALID_JSON_BODY_AS_OF_#{DateTime.now}"
      end
    end

    # filter all sensitive data stored in the credentials config
    Paasal::Spec::Config.credentials.sensitive_data.each do |replacement, replace|
      # enforce ASCII encoding to prevent VCR from crashing when credentials include umlauts or other characters
      c.filter_sensitive_data("__#{replacement}__") { |_i| replace.unpack('U*').map(&:chr).join }
    end
  end

  c.register_request_matcher :headers_no_auth do |request_1, request_2|
    # Anonymize header authentication
    headers_1 = request_1.headers
    headers_1['Authorization'] = '__AUTHORIZATION__' if headers_1.key?('Authorization')
    headers_1['User-Agent'] = '__USER_AGENT__' if headers_1.key?('User-Agent')

    headers_2 = request_2.headers
    headers_2['Authorization'] = '__AUTHORIZATION__' if headers_2.key?('Authorization')
    headers_2['User-Agent'] = '__USER_AGENT__' if headers_2.key?('User-Agent')

    # finally, compare headers
    headers_1 == headers_2
  end

  c.register_request_matcher :multipart_tempfile_agnostic_body do |request_1, request_2|
    # force custom boundary on multipart requests
    headers_1 = request_1.headers
    if headers_1.key?('Content-Type') && headers_1['Content-Type'][0].include?('boundary=')
      # harmonize random filename of tempfiles
      filename_1 = /filename="([-\.\w]+)"/i.match(request_1.body)
      request_1.body.gsub!(filename_1[1], 'filename="multipart-uploaded-file-by-paasal-42"') if filename_1
    end

    headers_2 = request_2.headers
    if headers_2.key?('Content-Type') && headers_2['Content-Type'][0].include?('boundary=')
      # harmonize random filename of tempfiles
      filename_2 = /filename="([-\.\w]+)"/i.match(request_2.body)
      request_2.body.gsub!(filename_2[1], 'filename="multipart-uploaded-file-by-paasal-42"') if filename_2
    end

    # execute default comparison
    request_1.body == request_2.body
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
end
