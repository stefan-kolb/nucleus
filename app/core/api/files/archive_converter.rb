module Paasal
  module Adapters
    module ArchiveConverter
      extend Paasal::Logging

      def self.convert(file, current_format, destination_format, sanitize = false)
        # skip if file is already in the valid format and no sanitizing is required
        return file if current_format == destination_format && sanitize == false

        begin
          extraction_dir = "#{Dir.tmpdir}/paasal.app.convert.cf.deploy.#{SecureRandom.uuid}"
          ArchiveExtractor.new.extract(file, extraction_dir, current_format)

          # sanitize if desired
          ApplicationRepoSanitizer.new.sanitize(extraction_dir) if sanitize

          return Archiver.new.compress(extraction_dir, destination_format)
        ensure
          # now delete the tmp directory again
          FileUtils.rm_rf(extraction_dir) if extraction_dir
        end
      end
    end
  end
end
