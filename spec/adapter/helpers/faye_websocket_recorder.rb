#!/usr/bin/env ruby
require 'digest/md5'
# for serialization to replace the default marshaller
require 'oj'

module Paasal
  # The {FayeWebsocketRecorder class} can be used to record and replay the interactions of a websocket
  # client with a server during rspec tests. <br>
  # When interactions are to be recorded (determined via {VCR}), the received messages are saved to individual files
  # that are valid only for the currently active websocket . <br>
  # During replay, the not-established websocket connection is ignored and the previously recorded messages
  # are dispatched to the requesting Client.<br>
  # <br>
  # This {FayeWebsocketRecorder class} is designed to only work with {VCR} and the {Faye::WebSocket::Client}, which
  # originates from the 'faye-websocket' gem.
  class FayeWebsocketRecorder
    # Create a new instance of the recorder.
    # @param [Object] test rspec test instance, provides access to `allow` and `receive` methods
    # @param [String] data_dir parent directory where to save or load the websocket messages
    def initialize(test, data_dir)
      @test = test
      @data_dir = data_dir
      @counter_semaphore = Mutex.new
      @counter = -1
    end

    # Enable recording / replay
    def enable
      @test.allow(Faye::WebSocket::Client).to @test.receive(:new).and_wrap_original do |om, *args|
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

    def record_websocket(*new_client_args)
      param_hash = args_hash(*new_client_args)
      dir = cassette_dir(param_hash)

      # delete previous recordings
      FileUtils.rm_r(dir) if File.exist? dir
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

      @test.allow_any_instance_of(Faye::WebSocket::Client).to(
        @test.receive(:dispatch_event).and_wrap_original do |om, *args|
          event = args[0]
          # record the event
          record_event(cassette_path(param_hash, event_number), event)
          # continue actual call, send event to the websocket listeners
          om.call(*args)
        end)

      # create the websocket and listen to messages
      yield
    end

    def replay_websocket_events(*new_client_args)
      replay_cassettes_dir = cassette_dir(args_hash(*new_client_args))
      fail StandardError,
           'Invalid playback request, no record for this websocket was found.' unless File.exist?(replay_cassettes_dir)

      captures_messages = 0
      @test.allow_any_instance_of(Faye::WebSocket::Client).to(
        @test.receive(:dispatch_event).and_wrap_original do |om, *args|
          @dispatching_method = om
          captures_messages += 1
          # suppress initial error and close events, due to non-availability of the actual websocket
          om.call(*args) if captures_messages >= 3
        end)

      event_cassettes = Queue.new
      Find.find(replay_cassettes_dir) { |f| event_cassettes.push(f) if File.file?(f) }

      dispatch_event = lambda do
        @dispatching_method.call(restore_event(event_cassettes.pop))
        # send a new message each 200ms
        EM.add_timer(0.2) { dispatch_event.call } if event_cassettes.length > 0
      end

      wait_until_dispatchable = lambda do
        if @dispatching_method && captures_messages == 2
          dispatch_event.call
        else
          EM.add_timer(0.5) { wait_until_dispatchable.call }
        end
      end
      wait_until_dispatchable.call

      # create the websocket that listens to messages
      yield
    end

    def restore_event(cassette)
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

    def hash_arg_hash(hash)
      md5 = Digest::MD5.new
      hash.each do |k, v|
        if v.is_a? Hash
          md5.update(hash_arg_hash(v))
        elsif k == 'Authorization'
          # skip authorization header, which is anonymized in replays
          md5.update("#{k} => 'anonymized'")
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
