module Paasal
  module ApiDetector
    # Get all API versions that are included in the project.
    # The API versions are identified by the presence of a directory below 'api/versions'.
    # An APIs directory will resolve to its version.
    # Therefore, if there is a directory 'api/versions/v3', 'v3' will be on of the returned versions.
    # The method caches its detected versions and returns the previous result if called multiple times.
    #
    # @return [Array<String>] names of the API versions
    def self.api_versions
      return @detected_api_versions if @detected_api_versions
      api_versions_dir = 'app/api/versions/*'
      # ... looking for API versions at '#{api_versions_dir}'
      api_versions = []
      api_dirs = Dir.glob(api_versions_dir).select { |f| File.directory? f }
      api_dirs.each do |api_dir|
        api_versions << File.basename(api_dir)
      end unless api_dirs.nil?
      # ... found #{api_versions.size} API versions: #{api_versions.join(', ')}
      @detected_api_versions = api_versions
      @detected_api_versions
    end
  end
end
