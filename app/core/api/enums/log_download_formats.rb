module Paasal
  module API
    module LogDownloadFormats
      LOG = 'log'
      TAR_GZ = 'tar.gz'
      ZIP = 'zip'

      # List all available file formats.
      # @return [Array<String>] file format as file extensions
      def self.all
        constants.collect { |constant| const_get constant }
      end
    end
  end
end
