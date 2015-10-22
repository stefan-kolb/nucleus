module Nucleus
  class Archiver
    def initialize(exclude_git = true)
      @exclude_git = exclude_git
    end

    # Compress the files of the path into an archive, using the compression format,
    # which indicates which method must be used to compress the archive.
    # @param [String] path which directory's contents are going to be compressed into the archive
    # @param [String] compression_format represented by well-known file extensions, e.g. zip or tar.gz
    # @raise [StandardError] if the compression_format is not supported and the directory can't be compressed
    # @return [StringIO] compressed data of the given input path
    def compress(path, compression_format)
      compression_method = compression_format.downcase.gsub(/\./, '_').underscore.to_sym
      fail StandardError,
           "Unsupported compression format #{compression_format}" unless self.respond_to?(compression_method, true)
      send(compression_method, path)
    end

    private

    def tar(path)
      string_io = StringIO.new('')
      Gem::Package::TarWriter.new(string_io) do |tar|
        Find.find(path) do |file|
          # do not include the git files
          next if @exclude_git && file.start_with?("#{path}/.git")

          mode = File.stat(file).mode
          relative_file = file.sub(%r{^#{Regexp.escape path}\/?}, '')

          if File.directory?(file)
            tar.mkdir relative_file, mode
          else
            tar.add_file relative_file, mode do |tf|
              File.open(file, 'rb') { |f| tf.write f.read }
            end
          end
        end
      end
      string_io.rewind
      string_io
    end

    def tar_gz(path)
      tar_file = tar(path)
      begin
        gz = StringIO.new('')
        z = Zlib::GzipWriter.new(gz)
        z.write tar_file.string
      ensure
        z.close unless z.nil?
      end

      # z was closed to write the gzip footer, so
      # now we need a new StringIO
      StringIO.new gz.string
    end

    def zip(path)
      string_io = Zip::OutputStream.write_buffer do |zio|
        Find.find(path) do |file|
          # do not process directories && do not include the Git DB files
          next if File.directory?(file) || (@exclude_git && file.start_with?("#{path}/.git"))

          relative_file = file.sub(%r{^#{Regexp.escape path}\/?}, '')
          zio.put_next_entry(relative_file)
          File.open(file, 'rb') do |f|
            zio.write f.read
          end
        end
      end
      string_io.rewind
      string_io
    end

    def write_zip_entries(path, sub_path, io)
      search_path = File.join(path, sub_path)
      Find.find(path) do |file|
        zip_file_path = file.sub(%r{^#{Regexp.escape search_path}\/?}, '')
        next if @exclude_git && zip_file_path.start_with?('.git')
        if File.directory?(file)
          io.mkdir(zip_file_path)
          write_zip_entries(path, zip_file_path, io)
        else
          io.get_output_stream(zip_file_path) { |f| f.print(File.open(file, 'rb').read) }
        end
      end
    end
  end
end
