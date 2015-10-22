module Nucleus
  class ApplicationRepoSanitizer
    include Nucleus::Logging

    # Create a new instance of the object.
    # @param [Boolean] exclude_git if true the '.git' directory won't be moved up, but will be ignored.
    def initialize(exclude_git = true)
      @exclude_git = exclude_git
    end

    # Sanitizing the repository_dir will check if the repository has more than one file / directory besides the git DB.
    # If there is only one directory, all files in this directory are going to be moved one level up.
    # If there was:
    #
    #     .git
    #     wordfinder
    #
    # All contents of `wordfinder` will be moved one level up, resulting in:
    #
    #     config
    #     lib
    #     public
    #     specs
    #     views
    #     README.md
    #     server.js
    #     ...
    #
    # @param [String] repository_dir path to the git repository that is going to be sanitized
    def sanitize(repository_dir)
      # no sanitizing for files
      return unless File.directory?(repository_dir)
      repo_entries = sanitized_dir_entries(repository_dir)
      return unless repo_entries.length == 1

      log.debug 'Uploaded application is wrapped in folder, fixing now by moving all contents one level up...'
      dir = File.join(repository_dir, repo_entries[0])
      dir_entries = sanitized_dir_entries(dir).map { |name| File.join(dir, name) }
      FileUtils.mv(dir_entries, repository_dir)
      # Now delete the usually empty directory
      FileUtils.rm_r dir
    end

    private

    def sanitized_dir_entries(dir)
      Dir.entries(dir).reject do |entry|
        entry == '.DS_Store' || (@exclude_git && entry == '.git') || entry == '.' || entry == '..'
      end
    end
  end
end
