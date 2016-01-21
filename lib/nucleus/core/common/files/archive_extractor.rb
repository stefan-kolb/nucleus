module Nucleus
  class ArchiveExtractor
    def initialize(exclude_git = true)
      @exclude_git = exclude_git
    end

    # Extract the file to the destination path.
    # The compression format indicates which method must be used to extract the archive.
    # @param [IO] file in-memory archive file to extract
    # @param [String] destination_path where the archive is going to be extracted to
    # @param [String] compression_format represented by well-known file extensions, e.g. zip or tar.gz
    # @raise [StandardError] if the compression_format is not supported and can't be extracted
    # @return [Integer] number of extracted files
    def extract(file, destination_path, compression_format)
      compression_method = compression_format_method_name(compression_format)
      fail StandardError, 'Unsupported compression format' unless respond_to?(compression_method, true)

      # be sure that directory exists
      FileUtils.mkdir_p(destination_path, verbose: false)

      begin
        send(compression_method, file, destination_path)
      rescue Zip::Error, Zlib::GzipFile::Error
        raise API::Errors::ApplicationArchiveError, "Failed to extract #{compression_format} archive"
      end
    end

    # Checks if the compression format is supported and an archive of this type could be extracted.
    # @param [String] compression_format represented by well-known file extensions, e.g. zip or tar.gz
    # @return [Boolean] true if format is supported, false if not
    def supports?(compression_format)
      compression_method = compression_format_method_name(compression_format)
      respond_to?(compression_method, true)
    end

    private

    def compression_format_method_name(compression_format)
      "un_#{compression_format.downcase.tr('.', '_').underscore}".to_sym
    end

    def un_zip(file, destination_path)
      extracted = 0
      Zip::File.open(file) do |zip_file|
        # Handle entries one by one
        zip_file.each do |entry|
          next if @exclude_git && entry.name.start_with?('.git')
          dest = File.join(destination_path, entry.name)
          if entry.name_is_directory?
            FileUtils.mkdir_p(dest) unless File.exist?(dest)
          else
            # make sure parent directory exists
            FileUtils.mkdir_p(File.expand_path('..', dest))

            entry.extract(dest) unless File.exist?(dest)
            # increase count
            extracted += 1
          end
        end
      end
      extracted
    end

    def un_tar_gz(file, destination_path)
      extracted = 0
      # unzip the archive into the repo, closes resource automatically
      # Thanks to Draco Ater: http://stackoverflow.com/a/19139114/1009436
      Gem::Package::TarReader.new(Zlib::GzipReader.open(file)) do |tar|
        dest = nil
        tar.each do |entry|
          # Process Longlinks and skip to next entry
          if entry.full_name == '././@LongLink'
            dest = File.join(destination_path, entry.read.strip)
            next
          end

          # Process default entry types (dir, file, symlink)
          full_name = entry.full_name.sub(%r{(\.\/)?}, '')
          dest ||= File.join(destination_path, full_name)
          next if tar_git_entry? full_name
          if entry.directory?
            write_tar_dir_entry(entry, dest)
          elsif entry.file?
            write_tar_file_entry(entry, dest)
            # increase count
            extracted += 1
          elsif entry.header.typeflag == '2'
            # handle symlinks
            File.symlink(entry.header.linkname, dest)
          end
          dest = nil
        end
      end
    end
    alias un_tgz un_tar_gz

    def tar_git_entry?(full_name)
      @exclude_git && full_name.start_with?('._.git', '.git')
    end

    def write_tar_file_entry(entry, dest)
      FileUtils.rm_rf(dest) if File.directory?(dest)
      File.open(dest, 'wb') { |f| f.print entry.read }
      FileUtils.chmod(entry.header.mode, dest, verbose: false)
    end

    def write_tar_dir_entry(entry, dest)
      File.delete(dest) if File.file?(dest)
      FileUtils.mkdir_p(dest, mode: entry.header.mode, verbose: false)
    end
  end
end
