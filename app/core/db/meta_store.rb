require 'filesize'

module Paasal
  module DB
    class MetaStore
      include Paasal::Logging

      def get_files
        files = Dir["#{configatron.db.path}**"]
        log.debug "Found files: #{files}"
        files
      end

      def tidy_all
        log.debug('Tidying all DB stores...')
        db_files = get_files
        unless db_files.nil?
          db_files.each do |db_file|
            # skip directories
            next if File.directory? db_file
            tidy_file(db_file)
          end
        end
      end

      private

      def tidy_file(db_file)
        log.debug("... tidy #{db_file}")
        begin
          db = Daybreak::DB.new(db_file)
          original_size = Filesize.from("#{db.bytesize} B").pretty
          db.compact
          shrinked_size = Filesize.from("#{db.bytesize} B").pretty
          log.debug("... reduced size from #{original_size} to #{shrinked_size}") unless original_size == shrinked_size
        ensure
          db.close unless db.nil?
        end
      end

    end
  end
end
