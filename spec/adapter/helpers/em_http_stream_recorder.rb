#!/usr/bin/env ruby
require 'digest/md5'
# for serialization to replace the default marshaller
require 'oj'

module Nucleus
  # The {EmHttpStreamRecorder class} can be used to record and replay the interactions of a EM http request stream
  # during rspec tests. <br>
  # When interactions are to be recorded (determined via {VCR}), the received messages are saved to individual files
  # that are valid only for the currently active connection. <br>
  # During replay, the not-established http connection is ignored and the previously recorded messages
  # are dispatched to the requesting Client.<br>
  # <br>
  # This {EmHttpStreamRecorder class} is designed to only work with {VCR} and the {EventMachine::HttpClient},
  # which originates from the 'em-http-request' gem.
  class EmHttpStreamRecorder
    CONN = EventMachine::HttpConnection
    STUB = EventMachine::HttpStubConnection
    # Create a new instance of the recorder.
    # @param [Object] test rspec test instance, provides access to `allow` and `receive` methods
    # @param [String] data_dir parent directory where to save or load the http stream messages
    def initialize(test, data_dir)
      @test = test
      @data_dir = data_dir
      @counter_semaphore = Mutex.new
      @counter = -1
    end

    # Enable recording / replay
    def enable
      @test.allow(EventMachine::HttpRequest).to @test.receive(:new).and_wrap_original do |om, *args|
        if VCR.current_cassette.recording?
          record_chunks(*args) { om.call(*args) }
        else
          replay_chunks(*args) { om.call(*args) }
        end
      end
    end

    private

    def chunk_number
      @counter_semaphore.synchronize do
        @counter += 1
        return @counter
      end
    end

    def record_chunks(*new_client_args)
      param_hash = args_hash(*new_client_args)
      dir = cassette_dir(param_hash)

      # delete previous recordings
      FileUtils.rm_r(dir) if File.exist? dir
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

      @test.allow_any_instance_of(STUB).to @test.receive(:receive_data).and_wrap_original do |om, *args|
        chunk = args[0]
        # record the chunk
        record_chunk(cassette_path(param_hash, chunk_number), chunk)
        # continue actual call
        om.call(*args)
      end

      # create the http connection that listens to messages
      yield
    end

    def replay_chunks(*new_client_args)
      replay_cassettes_dir = cassette_dir(args_hash(*new_client_args))
      raise StandardError, 'Invalid playback request, no record for this http stream connection was found.' unless File.exist?(replay_cassettes_dir)

      setup_chunk_replay_mock(replay_cassettes_dir)
      setup_http_connection_mock

      # create the http connection that listens to messages
      yield
    end

    def setup_http_connection_mock
      # fake successful http connection
      @test.allow(EventMachine).to @test.receive(:bind_connect) do |*args, &block|
        @connection = STUB.new("nucleus.test.conn.to.#{args[2]}.#{SecureRandom.uuid}", args)
        # ignore timeouts that are being applied
        @test.allow(@connection).to @test.receive(:pending_connect_timeout=) {}
        @test.allow(@connection).to @test.receive(:comm_inactivity_timeout=) {}
        # yield if block was given
        block.call(@connection) if block
        @connection
      end
    end

    def setup_chunk_replay_mock(replay_cassettes_dir)
      @test.allow_any_instance_of(CONN).to @test.receive(:activate_connection).and_wrap_original do |om, *args|
        om.call(*args)
        # once connected, start pushing chunks
        chunk_cassettes = Queue.new
        Find.find(replay_cassettes_dir) { |f| chunk_cassettes.push(f) if File.file?(f) }
        dispatch_chunk = lambda do
          @connection.receive_data(replay_chunk(chunk_cassettes.pop))
          # send a new message each 200ms
          EM.add_timer(0.2) { dispatch_chunk.call } unless chunk_cassettes.empty?
        end
        EM.add_timer(1) { dispatch_chunk.call }
      end
    end

    def replay_chunk(cassette)
      Oj.load(File.read(cassette))
    end

    def record_chunk(cassette, chunk)
      File.open(cassette, 'w') do |file|
        file.puts Oj.dump(chunk)
      end
    end

    # Return all recorded chunks within the directory.
    # Returns the chunks sorted in ascending order, starting with chunk 0, up to n
    def chunks(dir)
      files = []
      Find.find(dir) do |f|
        chunk_number = /recorded_(\d+)/.match(File.basename(f))[1]
        files[chunk_number] = f
      end
      files
    end

    def cassette_path(param_hash, msg_nr)
      File.join(cassette_dir(param_hash), "response_#{msg_nr}")
    end

    def cassette_dir(hash)
      File.join(@data_dir, 'em-http-request', hash)
    end

    def hash_arg_hash(hash)
      md5 = Digest::MD5.new
      hash.each do |k, v|
        if v.is_a? Hash
          md5.update(hash_arg_hash(v))
        else
          md5.update("#{k} => #{v}")
        end
      end
      md5.hexdigest
    end

    def args_hash(*args)
      # calculate hash and take care of IO objects, hashes, ...
      md5 = Digest::MD5.new
      args.each do |arg|
        case arg
        when Hash
          md5.update(hash_arg_hash(arg))
        else
          md5.update(arg.to_s)
        end
      end
      md5.hexdigest
    end
  end
end
