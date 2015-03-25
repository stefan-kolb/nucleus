require 'airborne'
require 'rspec/wait'
require 'scripts/initialize_core'
require 'scripts/initialize_rack'
require 'spec/spec_helper'
require 'spec/support/shared_example_request_types'
require 'spec/adapter/credentials_helper'
require 'spec/adapter/method_response_recorder'
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

def example_group_property(metadata, property)
  example_group_property = metadata.key?(:example_group) ? metadata[:example_group][property] : false
  parent_group_property = metadata.key?(:parent_example_group) ? metadata[:parent_example_group][property] : false

  # process recursive
  return example_group_property(metadata[:parent_example_group], property) if parent_group_property
  return metadata[:example_group] if example_group_property
  # property for the shared example group was not found
  nil
end

# used to calculate the MD5 sums of all files in a deployed application archive
def deployed_files_md5(deployed_archive, deployed_archive_format)
  # extract deployed archive and sanitize to allow a fair comparison
  dir_deployed = "#{Dir.tmpdir}/paasal.test.#{SecureRandom.uuid}_deployed"
  Paasal::ArchiveExtractor.new.extract(deployed_archive, dir_deployed, deployed_archive_format)
  Paasal::ApplicationRepoSanitizer.new.sanitize(dir_deployed)

  # generate MD5 hashes of deployed files
  deployed_md5 = {}
  Find.find(dir_deployed) do |file|
    next if File.directory? file
    relative_name = file.sub(/^#{Regexp.escape dir_deployed}\/?/, '')
    deployed_md5[relative_name] = Digest::MD5.file(file).hexdigest
  end
  deployed_md5
ensure
  FileUtils.rm_r(dir_deployed) unless dir_deployed.nil?
end

# used to calculate the MD5 sums of all files in a received application download response
def response_files_md5(response, downlaod_archive_format)
  response_file = "#{Dir.tmpdir}/paasal.test.#{SecureRandom.uuid}_response"
  # write response to disk
  File.open(response_file, 'wb') { |file| file.write response }

  # extract downloaded response and sanitize to allow a fair comparison
  dir_download = "#{Dir.tmpdir}/paasal.test.#{SecureRandom.uuid}_downlaod"
  Paasal::ArchiveExtractor.new.extract(response_file, dir_download, downlaod_archive_format)
  Paasal::ApplicationRepoSanitizer.new.sanitize(dir_download)

  # generate MD5 hashes of downloaded files
  downlaod_md5 = {}
  Find.find(dir_download) do |file|
    next if File.directory? file
    relative_name = file.sub(/^#{Regexp.escape dir_download}\/?/, '')
    downlaod_md5[relative_name] = Digest::MD5.file(file).hexdigest
  end
  downlaod_md5
ensure
  FileUtils.rm(response_file) unless response_file.nil?
  FileUtils.rm_r(dir_download) unless dir_download.nil?
end

################
# RSPEC CONFIG #
################

RSpec.configure do |config|
  vendor_name = lambda do |meta|
    meta[:described_class].to_s.gsub(/Paasal::Adapters::/, '').underscore.downcase.gsub(/_adapter/, '')
  end

  vcr_cassette_name_for = lambda do |meta|
    description = meta[:description]
    example_group = meta.key?(:example_group) ? meta[:example_group] : meta[:parent_example_group]
    return File.join(vcr_cassette_name_for[example_group], description) if example_group
    # modify adapter name and split by API version
    File.join(description.gsub(/Paasal::Adapters::/, '').underscore.downcase.gsub(/_adapter/, ''), 'vcr_cassettes')
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
    group_cassette = example_group_property(example.metadata, :as_cassette)
    group_mock_fs = example_group_property(example.metadata, :mock_fs_on_replay)
    cassette_name = group_cassette ? vcr_cassette_name_for[group_cassette] : vcr_cassette_name_for[example.metadata]

    # Use complete request to raise errors and require new cassettes as soon as the request changes (!)
    # Use exclusive option to prevent accidental matching requests in different application states
    VCR.insert_cassette(cassette_name, exclusive: true,
                        allow_unused_http_interactions: false,
                        match_requests_on: [:method, :uri_no_auth, :multipart_tempfile_agnostic_body, :headers_no_auth],
                        decode_compressed_response: true)

    # Fake Git and Filesystem interactions on replay
    if group_mock_fs
      # fake UUIDs to have identical filenames in repetitive tests
      allow(SecureRandom).to receive(:uuid) do
        @counter = '000000000000' unless @counter
        "2d931510-d99f-494a-8c67-#{@counter.next!}"
      end

      tmpfile_name = lambda do |prefix_suffix|
        case prefix_suffix
        when String
          prefix = prefix_suffix
          suffix = ''
        when Array
          prefix = prefix_suffix[0]
          suffix = prefix_suffix[1]
        else
          fail ArgumentError, "unexpected prefix_suffix: #{prefix_suffix.inspect}"
        end
        # random part of equal length (!) so that the message length is always equal
        random_part = (0...16).map { (65 + rand(26)).chr }.join
        "#{prefix}-paasal-created-tempfile-#{random_part}#{suffix}"
      end

      # fake random filename generation for tmpfiles if using Ruby < 2.1
      allow_any_instance_of(Dir::Tmpname).to receive(:make_tmpname) do |_instance, prefix_suffix, _n|
        tmpfile_name.call(prefix_suffix)
      end

      # fake random filename generation for tmpfiles if using Ruby >= 2.1
      allow(Dir::Tmpname).to receive(:make_tmpname) do |prefix_suffix, _n|
        tmpfile_name.call(prefix_suffix)
      end

      # force a static boundary
      allow_any_instance_of(RestClient::Payload::Multipart).to receive(:boundary) do
        'PaaSal771096PaaSal'
      end

      recorder = Paasal::MethodResponseRecorder.new(File.join(File.dirname(__FILE__), 'recordings',
                                                              vendor_name[example.metadata], 'method_cassettes'))
      recorder.setup(self, Paasal::Adapters::GitDeployer, [:trigger_build, :deploy, :download])
      recorder.setup(self, Paasal::Adapters::FileManager, [:save_file_from_data, :load_file])
      recorder.setup(self, Paasal::Adapters::ArchiveConverter, [:convert])
    end
  end

  config.after(:each) do |test|
    example = test.respond_to?(:metadata) ? test : test.example
    VCR.eject_cassette(skip_no_unused_interactions_assertion: !example.exception.nil?)
    # clear request store
    RequestStore.clear!
  end
end

########################
# VCR CONFIG & FILTERS #
########################

VCR.configure do |c|
  # save cassettes here
  c.cassette_library_dir = File.join(File.dirname(__FILE__), 'recordings')
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
      rescue
        "INVALID_JSON_BODY_AS_OF_#{DateTime.now}"
      end
    end
  end

  def filter_request_body(vcr_config, key)
    vcr_config.filter_sensitive_data("__#{key.underscore.upcase}__") do |i|
      # TODO: skipping multipart / ASCII-8BIT requests for now
      if multipart?(i) && !i.request.body.encoding.to_s == 'ASCII-8BIT'
        request_body = i.request.body.nil? || i.request.body.empty? ? {} : MultiJson.load(i.request.body)
        if request_body.is_a? Array
          request_body.each { |entry| filter_body(entry, key, 'REQUEST') }
        else
          filter_body(request_body, key, 'REQUEST')
        end
      end
    end
  end

  def multipart?(i)
    i.request.headers['Content-Type'] && !i.request.headers['Content-Type'][0].start_with?('multipart/form')
  end

  %w(token).each { |key| filter_query(c, key) }
  %w(Authorization).each { |key| filter_header(c, key) }
  %w(api_key token refresh_token access_token).each do |key|
    filter_request_body(c, key)
    filter_response_body(c, key)
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

    # excute default comparison
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

  # filter heroku user identification
  c.filter_sensitive_data('__USER_ID__@users.heroku.com') do |i|
    begin
      response_body = i.response.body.nil? || i.response.body.empty? ? {} : MultiJson.load(i.response.body)
      if response_body.is_a?(Hash) && /^\S+@users.heroku.com$/ =~ response_body['id']
        response_body['id']
      else
        "NO_HEROKU_USER_ID_IN_RESPONSE_BODY_TO_REPLACE_AS_OF_#{DateTime.now}"
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
