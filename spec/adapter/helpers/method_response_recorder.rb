#!/usr/bin/env ruby
require 'digest/md5'
# for serialization to replace the default marshaller
require 'oj'

module Nucleus
  class MethodResponseRecorder
    def initialize(test, example, data_dir)
      @example_group_name = example.metadata[:example_group][:full_description]
      @test = test
      @data_dir = data_dir
    end

    def setup(class_name, methods)
      methods.each do |method|
        # for class methods
        @test.allow_any_instance_of(class_name).to @test.receive(method).and_wrap_original do |original_method, *args|
          if VCR.current_cassette.recording?
            record(class_name, method, *args) { original_method.call(*args) }
          else
            playback(class_name, method, *args)
          end
        end
        # for module methods
        @test.allow(class_name).to @test.receive(method).and_wrap_original do |original_method, *args|
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
      unless File.exist?(cassette)
        raise StandardError, 'Invalid playback request. Could not find any cassette matching the '\
          'class and argument combination'
      end

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
      unless File.exist?(cassette)
        raise StandardError, 'Invalid playback request. Could not find any cassette matching the '\
          "class and argument combination: #{cassette}"
      end

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
      unless File.exist?(cassette)
        raise StandardError, 'Invalid playback request. Could not find any cassette matching the '\
          "class and argument combination: #{cassette}"
      end

      response = Oj.load(File.read(cassette))
      raise response if response.is_a? Exception
      response
    end

    def write_io_recording(cassette, response)
      # rewind all IO objects
      response.rewind if response.respond_to?(:rewind)

      File.open(cassette, 'wb') do |file|
        # begin
        file.binmode
        file.write response.read
      end
    end

    def write_recording(cassette, response)
      File.open(cassette, 'w') do |file|
        file.puts Oj.dump(response)
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
      # Strip out the non-ascii characters of method names, e.g. question marks
      method_name_sanitized = method_name.to_s.underscore.gsub(/[^0-9A-Za-z.\-]/, '_')
      File.join(@data_dir, class_name.to_s.underscore, method_name_sanitized, hash)
    end

    # FIXME: introduces matching problems with arguments like Hashes
    def args_hash(*args)
      # calculate hash and take care of IO objects, hashes, ...
      md5 = Digest::MD5.new
      args.each do |arg|
        case arg
        when File
          File.open(arg, 'rb') { |io| digest_io_update(md5, io) }
        when Data, IO, Tempfile
          digest_io_update(md5, arg)
        else
          md5.update(arg.to_s)
        end
      end
      # update with the test name, so that failing tests do not influence others
      md5.update(@example_group_name)
      md5.hexdigest
    end

    def digest_io_update(digest, io)
      io.binmode
      io.rewind if io.respond_to?(:rewind)
      while (buf = io.read(4096)) && !buf.empty?
        digest.update(buf)
      end
      io.rewind if io.respond_to?(:rewind)
    end
  end
end
