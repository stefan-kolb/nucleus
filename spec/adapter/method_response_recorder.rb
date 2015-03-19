#!/usr/bin/env ruby
require 'digest/md5'

module Paasal
  class MethodResponseRecorder
    def initialize(data_dir)
      @data_dir = data_dir
    end

    def setup(test, class_name, methods)
      methods.each do |method|
        # for class methods
        test.allow_any_instance_of(class_name).to test.receive(method).and_wrap_original do |original_method, *args|
          if VCR.current_cassette.recording?
            record(class_name, method, *args) { original_method.call(*args) }
          else
            playback(class_name, method, *args)
          end
        end
        # for module methods
        test.allow(class_name).to test.receive(method).and_wrap_original do |original_method, *args|
          if VCR.current_cassette.recording?
            record(class_name, method, *args) { original_method.call(*args) }
          else
            playback(class_name, method, *args)
          end
        end
      end
    end

    private

    def record(class_name, method_name, *args)
      param_hash = args_hash(*args)
      begin
        method_response = yield
      rescue StandardError => e
        method_response = e
      end

      dir = cassette_dir(class_name, method_name, param_hash)
      cassette = cassette_path(method_response, class_name, method_name, param_hash)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      # delete previous recordings
      FileUtils.rm(cassette) if File.exist? cassette

      # now write the response to the file
      if io?(method_response) || tempfile?(method_response)
        write_io_recording cassette, method_response
      else
        write_recording cassette, method_response
      end

      # fire playback from the created recording
      playback(class_name, method_name, *args)
    end

    def playback(class_name, method_name, *args)
      param_hash = args_hash(*args)
      return play_io(class_name, method_name, param_hash) if play_io?(class_name, method_name, param_hash)
      return play_tempfile(class_name, method_name, param_hash) if play_tempfile?(class_name, method_name, param_hash)
      play(class_name, method_name, param_hash)
    end

    def play_io?(class_name, method_name, param_hash)
      File.exist?(File.join(cassette_dir(class_name, method_name, param_hash), 'io_response'))
    end

    def play_tempfile?(class_name, method_name, param_hash)
      File.exist?(File.join(cassette_dir(class_name, method_name, param_hash), 'tempfile_response'))
    end

    def play_io(class_name, method_name, param_hash)
      cassette = File.join(cassette_dir(class_name, method_name, param_hash), 'io_response')
      fail StandardError, 'Invalid playback request. Could not find any cassette matching the '\
        'class and argument combination' unless File.exist?(cassette)

      response = StringIO.new('')
      File.open(cassette, 'rb') do |file|
        # begin
        file.binmode
        response.write file.read
      end
      response.rewind
      response
    end

    def play_tempfile(class_name, method_name, param_hash)
      cassette = File.join(cassette_dir(class_name, method_name, param_hash), 'tempfile_response')
      fail StandardError, 'Invalid playback request. Could not find any cassette matching the '\
        "class and argument combination: #{cassette}" unless File.exist?(cassette)

      response = Tempfile.new([param_hash, '.zip'])
      File.open(cassette, 'rb') do |file|
        # begin
        file.binmode
        response.write file.read
      end
      response.rewind
      response
    end

    def play(class_name, method_name, param_hash)
      cassette = File.join(cassette_dir(class_name, method_name, param_hash), 'response')
      fail StandardError, 'Invalid playback request. Could not find any cassette matching the '\
        "class and argument combination: #{cassette}" unless File.exist?(cassette)

      response = Marshal.restore(File.read(cassette))
      fail response if response.is_a? StandardError
      response
    end

    def write_io_recording(cassette, response)
      # rewind all IO objects
      response.rewind if response.respond_to?(:rewind)
      response.rewind if response.respond_to?(:rewind)

      File.open(cassette, 'wb') do |file|
        # begin
        file.binmode
        file.write response.read
      end
    end

    def write_recording(cassette, response)
      File.open(cassette, 'w') do |file|
        # begin
        file.puts Marshal.dump(response)
      end
    end

    def io?(response)
      return true if response.is_a?(Data) || response.is_a?(IO)
      false
    end

    def tempfile?(response)
      return true if response.is_a?(Tempfile)
      false
    end

    def cassette_path(response, clazz, method_name, param_hash)
      return File.join(cassette_dir(clazz, method_name, param_hash), 'io_response') if io?(response)
      return File.join(cassette_dir(clazz, method_name, param_hash), 'tempfile_response') if tempfile?(response)
      File.join(cassette_dir(clazz, method_name, param_hash), 'response')
    end

    def cassette_dir(class_name, method_name, hash)
      File.join(@data_dir, class_name.to_s.underscore, method_name.to_s.underscore, hash)
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

    def digest_io_update(digest, io)
      io.rewind if io.respond_to?(:rewind)
      while (buf = io.read(4096)) && buf.length > 0
        digest.update(buf)
      end
      io.rewind if io.respond_to?(:rewind)
    end
  end
end
