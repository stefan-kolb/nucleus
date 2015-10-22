module Nucleus
  module API
    module Enums
      # Compression formats define which archives can be extracted and packed by Nucleus.
      # Users can upload data, or download them in any of the defined formats.
      module CompressionFormats
        # tar.gz, mime type application/gzip or application/x-gzip
        TAR_GZ = 'tar.gz'
        # zip, mime type application/zip
        ZIP = 'zip'

        # List all available compression formats.
        # @return [Array<String>] compression format as file extensions
        def self.all
          constants.collect { |constant| const_get constant }
        end
      end
    end
  end
end
