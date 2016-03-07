################
# RSPEC CONFIG #
################

RSpec.configure do |config|
  config.fail_fast = true

  vendor = lambda do |meta|
    meta[:described_class].to_s.gsub(/Nucleus::Adapters::/, '').underscore.downcase.gsub(/_adapter/, '')
  end

  # Build the cassette name. If no :cassette_group is set the name will be resolved recursively to:
  # {adapter}/vcr_cassettes/each/nested/rspec/example/group
  # But if there is a :cassette_group in any of the example groups, the path will be:
  # {adapter}/vcr_cassettes/parent/groups/{cassette_group}/nested/tests
  vcr_cassette_name_for = lambda do |meta|
    description = meta[:description]
    example_group = meta.key?(:example_group) ? meta[:example_group] : meta[:parent_example_group]
    if example_group
      if meta.key?(:cassette_group) && !meta[:parent_example_group].key?(:cassette_group)
        return File.join(vcr_cassette_name_for[example_group], *meta[:cassette_group].split(';'))
      end
      return File.join(vcr_cassette_name_for[example_group], description)
    end
    # modify adapter name and split by API version
    File.join(description.gsub(/Nucleus::Adapters::/, '').underscore.downcase.gsub(/_adapter/, ''), 'vcr_cassettes')
  end

  config.before(:suite) do
    # do a full application start, load entities and put them into the db stores
    Nucleus::API::AdapterImporter.new.import
    Excon.defaults[:mock] = false
  end

  config.after(:suite) do
    if File.exist?(nucleus_config.db.path) && File.directory?(nucleus_config.db.path)
      FileUtils.rm_rf(nucleus_config.db.path)
    end
  end

  config.before(:each) do |test|
    # clear authentication cache
    Nucleus::Adapters::BaseAdapter.auth_objects_cache.clear

    example = test.respond_to?(:metadata) ? test : test.example
    group_cassette = example_group_property(example.metadata, :as_cassette)
    group_mock_fs = example_group_property(example.metadata, :mock_fs_on_replay)
    group_mock_websocket = example_group_property(example.metadata, :mock_websocket_on_replay)
    cassette_name = group_cassette ? vcr_cassette_name_for[group_cassette] : vcr_cassette_name_for[example.metadata]
    # insert vcr cassette for each test
    # use tags so only credentials from this endpoint_id will be filtered
    if @endpoint
      VCR.insert_cassette(cassette_name, tag: @endpoint.to_sym)
    else
      VCR.insert_cassette(cassette_name)
    end

    # fake UUIDs to have identical filenames in repetitive tests
    allow(SecureRandom).to receive(:uuid) do
      @counter = '000000000000' unless @counter
      "2d931510-d99f-494a-8c67-#{@counter.next!}"
    end

    # Fake Git and Filesystem interactions on replay
    if group_mock_fs
      tmpfile_name = lambda do |prefix_suffix|
        case prefix_suffix
        when String
          prefix = prefix_suffix
          suffix = ''
        when Array
          prefix = prefix_suffix[0]
          suffix = prefix_suffix[1]
        else
          raise ArgumentError, "unexpected prefix_suffix: #{prefix_suffix.inspect}"
        end
        # random part of equal length (!) so that the message length is always equal
        random_part = (0...16).map { (65 + rand(26)).chr }.join
        "#{prefix}-nucleus-created-tempfile-#{random_part}#{suffix}"
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
        'Nucleus771096Nucleus'
      end

      method_path = File.join(__dir__, '..', 'recordings', vendor[example.metadata], 'method_cassettes')
      recorder = Nucleus::MethodResponseRecorder.new(self, example, File.expand_path(method_path))
      recorder.setup(Nucleus::Adapters::GitDeployer, [:trigger_build, :deploy, :download])
      recorder.setup(Nucleus::Adapters::GitRepoAnalyzer, [:any_branch?])
      recorder.setup(Nucleus::Adapters::FileManager, [:save_file_from_data, :load_file])
      recorder.setup(Nucleus::Adapters::ArchiveConverter, [:convert])
      recorder.setup(Nucleus::Adapters::V1::OpenshiftV2, [:remote_log_files, :remote_log_file?, :remote_log_entries])
    end

    if group_mock_websocket
      # enable faye websocket recording
      records_path = File.join(__dir__, '..', 'recordings', vendor[example.metadata])
      Nucleus::FayeWebsocketRecorder.new(self, File.expand_path(File.join(records_path, 'websocket_cassettes'))).enable
      Nucleus::EmHttpStreamRecorder.new(self, File.expand_path(File.join(records_path, 'http_stream_cassettes'))).enable
    end
  end

  config.after(:each) do |test|
    example = test.respond_to?(:metadata) ? test : test.example
    VCR.eject_cassette(skip_no_unused_interactions_assertion: !example.exception.nil?)
    # clear request store
    RequestStore.clear!
  end
end
