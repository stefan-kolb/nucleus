require 'airborne'
require 'rspec/wait'

# load the app packages
require 'scripts/initialize_core'
require 'scripts/initialize_rack'

# patch rspec so that all tests run in an EM reactor, as provided by the used Thin server
require 'spec/adapter/helpers/rspec_eventmachine_patch'

require 'spec/spec_helper'
require 'spec/adapter/helpers/credentials_helper'
require 'spec/adapter/helpers/method_response_recorder'
require 'spec/adapter/helpers/faye_websocket_recorder'
require 'spec/adapter/helpers/adapter_helper'
require 'spec/adapter/helpers/rspec_config_helper'
require 'spec/adapter/helpers/vcr_config_helper'

# require the actual adapter test files that contain the shared_examples
require 'spec/adapter/support/shared_example_adapters_valid_auth'
require 'spec/adapter/support/shared_example_adapters_invalid_auth'
require 'spec/support/shared_example_request_types'

# define (override from integration) test suite for coverage report
SimpleCov.command_name 'spec:suite:adapters'

# TODO: implement multi-version support for tests
# Setup the rack application, use API v1
Airborne.configure do |config|
  config.rack_app = Paasal::Rack.app(true)
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

def skip_example?(current_test, to_skip)
  return false if to_skip.nil? || to_skip.empty?
  adapter_spec_class = "RSpec::ExampleGroups::#{current_test.described_class.to_s.gsub(/::/, '')}"
  classes_to_skip = to_skip.collect do |test_name|
    class_to_skip = adapter_spec_class
    test_name.split(/\//).each do |subgroup|
      class_to_skip = "#{class_to_skip}::#{subgroup.split(/[\s,_,:,\/]/).map(&:capitalize).join}"
    end
    class_to_skip
  end
  classes_to_skip.each { |clazz_to_skip| return true if current_test.class.to_s.start_with?(clazz_to_skip) }
  false
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
  dir_deployed = File.join(Dir.tmpdir, "paasal.test.#{SecureRandom.uuid}_deployed")
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
def response_files_md5(response, downlaod_archive_format, sanitize = true)
  response_file = File.join(Dir.tmpdir, "paasal.test.#{SecureRandom.uuid}_response.#{downlaod_archive_format}")
  # write response to disk
  File.open(response_file, 'wb') { |file| file.write response }

  # extract downloaded response and sanitize to allow a fair comparison
  dir_download = File.join(Dir.tmpdir, "paasal.test.#{SecureRandom.uuid}_downlaod")
  Paasal::ArchiveExtractor.new.extract(response_file, dir_download, downlaod_archive_format)
  Paasal::ApplicationRepoSanitizer.new.sanitize(dir_download) if sanitize

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
