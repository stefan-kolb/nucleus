module Paasal
  module VersionDetector
    # Get all abstraction layer versions that are included in the project via the adapters.
    # The abstraction layer versions are identified by the presence of a directory below 'adapters/'.
    # An abstraction layer's directory will resolve to its version.
    # Therefore, if there is a directory 'adapters/v3', 'v3' will be on of the returned versions.
    # The method caches its detected versions and returns the previous result if called multiple times.
    #
    # @return [Array<String>] names of the abstraction layer versions
    def self.api_versions
      return @api_versions if @api_versions
      abstraction_layer_api_versions_dir = "#{Paasal.root}/lib/paasal/adapters/*"
      @api_versions = Dir.glob(abstraction_layer_api_versions_dir).map do |f|
        File.basename(f) if File.directory?(f)
      end.compact
    end
  end
end
