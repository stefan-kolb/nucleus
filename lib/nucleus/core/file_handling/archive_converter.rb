module Nucleus
  module Adapters
    # The {ArchiveConverter} shall be used within the adapters to prepare application containers for deployment
    # on the endpoint, by converting archives, e.g. from +tar.gz+ to +zip+, to match the endpoint APIs requirements.
    module ArchiveConverter
      extend Nucleus::Logging

      # Convert an archived application, the +file+, from the +current_format+ to the +destination_format+.
      # @param [IO] file archive file that shall be converted
      # @param [String] current_format represented by well-known file extensions, e.g. zip or tar.gz
      # @param [String] destination_format represented by well-known file extensions, e.g. zip or tar.gz
      # @param [Boolean] sanitize if true, the application will be sanitized, meaning if all data is in one folder
      #   it will be moved one level up so that the application data is not nested in another directory
      # @return [StringIO] the data of the input file in a new archive matching the destination format
      def self.convert(file, current_format, destination_format, sanitize = false)
        extraction_dir = "#{Dir.tmpdir}/nucleus.app.convert.cf.deploy.#{SecureRandom.uuid}"
        ArchiveExtractor.new.extract(file, extraction_dir, current_format)

        # sanitize if desired
        ApplicationRepoSanitizer.new.sanitize(extraction_dir) if sanitize

        Archiver.new.compress(extraction_dir, destination_format)
      ensure
        # now delete the tmp directory again
        FileUtils.rm_rf(extraction_dir) if extraction_dir
      end
    end
  end
end
