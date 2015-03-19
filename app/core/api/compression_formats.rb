module Paasal
  module API
    module CompressionFormats
      TAR_GZ = 'tar.gz'
      ZIP = 'zip'

      # List all available compression formats.
      # @return [Array<String>] compression format as file extensions
      def self.all
        constants.collect { |constant| const_get constant }
      end
    end
  end
end
