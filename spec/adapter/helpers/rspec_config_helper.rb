################
# RSPEC CONFIG #
################

RSpec.configure do |config|
  vendor = lambda do |meta|
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

      record_path = File.join(File.dirname(__FILE__), '..', 'recordings', vendor[example.metadata], 'method_cassettes')
      recorder = Paasal::MethodResponseRecorder.new(self, File.expand_path(record_path))
      recorder.setup(Paasal::Adapters::GitDeployer, [:trigger_build, :deploy, :download])
      recorder.setup(Paasal::Adapters::FileManager, [:save_file_from_data, :load_file])
      recorder.setup(Paasal::Adapters::ArchiveConverter, [:convert])
      record_path = File.join(File.dirname(__FILE__), '..', 'recordings', vendor[example.metadata], 'websocket_cassettes')
    end
  end

  config.after(:each) do |test|
    example = test.respond_to?(:metadata) ? test : test.example
    VCR.eject_cassette(skip_no_unused_interactions_assertion: !example.exception.nil?)
    # clear request store
    RequestStore.clear!
  end
end
