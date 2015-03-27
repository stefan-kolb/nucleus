#!/usr/bin/env ruby
require 'digest/md5'
# for serialization to replace the default marshaller
require 'oj'

module Paasal
  class FayeWebsocketRecorder
    def initialize(test, data_dir)
      @test = test
      @data_dir = data_dir
      @counter_semaphore = Mutex.new
      @counter = -1
    end

    def setup
      # for class methods
      @test.allow_any_instance_of(Faye::WebSocket::Client).to @test.receive(:new).and_wrap_original do |om, *args|
        p 'new was invoked for the websocket'
        if VCR.current_cassette.recording?
          record_websocket(*args) { om.call(*args) }
        else
          replay_websocket_events(*args) { om.call(*args) }
        end
      end
    end

    private

    def event_number
      @counter_semaphore.synchronize do
        @counter += 1
        return @counter
      end
    end

    def record_websocket(*args)
      param_hash = args_hash(*args)
      @websocket_identifier = param_hash

      dir = cassette_dir(param_hash)
      # delete previous recordings
      FileUtils.rm_r(dir) if File.exist? dir
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

      # mock events so that the messages will be recorded
      @test.allow(Faye::WebSocket::API::EventTarget).to @test.receive(:dispatch_event).and_wrap_original do |om, *args|
        event = args[0]
        p "Captured event: #{event.type}"
        p event
        # record the event
        record_event(cassette_path(param_hash, event_number), event)
        # continue actual call, send event to the websocket listeners
        om.call(*args)
      end

      # create the websocket and listen to messages
      yield
    end

    def replay_websocket_events(*args)
      # TODO: fake successful connection
      # TODO: replay events with minor delay
      param_hash = args_hash(*args)
      # @test.allow(Faye::WebSocket::API::EventTarget).to @test.receive(:dispatch_event).and_wrap_original do |om, *args|
      #   @dispatch_event = om
      # end

      # create the websocket that listens to messages
      yield
    end

    def play_event(cassette)
      Oj.load(File.read(cassette))
    end

    def record_event(cassette, event)
      File.open(cassette, 'w') do |file|
        file.puts Oj.dump(event)
      end
    end

    # Return all recorded events within the directory.
    # Returns the events sorted in ascending order, starting with event 0, up to n
    def events(dir)
      files = []
      Find.find(dir) do |f|
        event_number = /recorded_(\d+)/.match(File.basename(f))[1]
        files[event_number] = f
      end
      files
    end

    def cassette_path(param_hash, msg_nr)
      File.join(cassette_dir(param_hash), "response_#{msg_nr}")
    end

    def cassette_dir(hash)
      File.join(@data_dir, 'faye_websocket', hash)
    end

    def args_hash(*args)
      # calculate hash and take care of IO objects, hashes, ...
      md5 = Digest::MD5.new
      args.each do |arg|
        case arg
        when File
          File.open(arg) { |io| digest_io_update(md5, io) }
        when Data, IO, Tempfile
          digest_io_update(md5, arg)
        else
          md5.update(arg.to_s)
        end
      end
      md5.hexdigest
    end
  end
end
