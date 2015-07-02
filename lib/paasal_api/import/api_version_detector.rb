module Paasal
  module VersionDetector
    # Get all API versions that are included in the project.
    # The API versions are identified by the presence of a directory below 'api/versions'.
    # An APIs directory will resolve to its version.
    # Therefore, if there is a directory 'api/versions/v3', 'v3' will be on of the returned versions.
    # The method caches its detected versions and returns the previous result if called multiple times.
    #
    # @return [Array<String>] names of the API versions
    def self.api_versions
      return @api_versions if @api_versions
      # TODO: adapt when core and API are separated
      api_versions_dir = "#{Paasal.root}/lib/paasal_api/api/versions/*"
      @api_versions = Dir.glob(api_versions_dir).map do |f|
        File.basename(f) if File.directory?(f)
      end.compact
    end
  end
end
