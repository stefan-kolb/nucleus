module Nucleus
  module Adapters
    module FileManager
      extend Nucleus::Logging

      # Load the contents of the file.
      # @param [String] file absolute path of the file to read
      # @raise [Nucleus::FileExistenceError] if the file does not exist
      # @return [StringIO] binary contents of the file, rewinded
      def self.load_file(file)
        io = StringIO.new('')
        File.open(file, 'r') do |opened_file|
          opened_file.binmode
          io.write opened_file.read
        end
        io.rewind
        io
      end

      # Save the data from within the {::Data} object to the file.
      # By default, this replaces already existing files.
      # If force is set to false, the method call will fail if there already is a file at the destination.
      # If force is false, but expected_file_md5_hex is specified, the file will be replaced as long as
      # the hexdigest of the current file is equal to the expected_file_md5_hex param.
      #
      # @param [String] file absolute path of the file to write to
      # @param [Data] io data to write to the file
      # @param [Boolean] force if true file is replaced, else write fails
      # @param [String] expected_file_md5_hex MD5 hexdigest of the expected file to be replaced.
      # If nil, file is not replaced as long as force == false
      # @raise [Nucleus::FileExistenceError] if the file already existed
      # @raise [ArgumentError] if expected_file_md5_hex did not match the MD5 hexdigest of the current file
      # in the repository
      # @return [void]
      def self.save_file_from_data(file, io, force = true, expected_file_md5_hex = nil)
        if File.exist? file
          unless force
            # fail if file exists, but shall not be replaced
            raise Nucleus::FileExistenceError, 'File already exists' if expected_file_md5_hex.nil?

            # do only replace if file is as expected
            actual_hex = Digest::MD5.file(file).hexdigest
            unless actual_hex == expected_file_md5_hex
              raise ArgumentError, "File to replace does exist, but hash sum is different than expected: #{actual_hex}"
            end
          end
        end

        # rewind IO
        io.rewind if io.respond_to? :rewind

        # create parent directory
        dirname = File.dirname(file)
        FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

        # write file and replace existing
        File.open(file, 'w') do |opened_file|
          opened_file.binmode
          opened_file.write io.read
        end
      end
    end
  end
end
