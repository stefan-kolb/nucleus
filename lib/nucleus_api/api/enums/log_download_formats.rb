module Nucleus
  module API
    module Enums
      # {LogDownloadFormats} define the filetypes that can be requested for logs to be downloaded with.
      module LogDownloadFormats
        # log (raw/uncompressed), mime type usually is text/plain or text/html
        LOG = 'log'.freeze
        # tar.gz, mime type application/gzip or application/x-gzip
        TAR_GZ = 'tar.gz'.freeze
        # zip, mime type application/zip
        ZIP = 'zip'.freeze

        # List all available file formats.
        # @return [Array<String>] file format as file extensions
        def self.all
          constants.collect { |constant| const_get constant }
        end
      end
    end
  end
end
