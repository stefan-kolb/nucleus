module Paasal
  module Adapters
    class GitDeployer
      include Paasal::Logging

      # TODO: write unit tests

      # Initialize a new instance of the GitDeployer
      # @param [String] user_email email address of the user, used as author of commits
      # @param [String] repo_url address where the repository can be retrieved
      # @param [String] repo_name name of the directory for the repository that shall be created in the tmp dir
      # @param [String] repo_branch branch to push to
      def initialize(repo_name, repo_url, user_email, repo_branch = 'master')
        @repo_name = repo_name
        @repo_url = repo_url
        @repo_branch = repo_branch
        @user_email = user_email
      end

      # Force a build using the latest git commit.
      # To enforce the new build, a file 'paasal-rebuild-trigger'
      # gets created or updated in the repository and the changes will be pushed.
      # @return [void]
      def trigger_build
        push_repository_changes do |repo_dir|
          # add a custom file that always changes the data and triggers a new build
          build_trigger_file = File.join(repo_dir, 'paasal-rebuild-trigger')
          current_md5 = File.exist?(build_trigger_file) ? Digest::MD5.file(build_trigger_file).hexdigest : nil
          data = StringIO.new("PaaSal rebuild, triggered at #{Time.now}")
          FileManager.save_file_from_data(build_trigger_file, data, false, current_md5)
        end
        nil
      end

      # Deploys the contents of the archive file to the repository that resides at the repo_url.
      #
      # @param [File] file archive file whose contents shall be deployed to the repository
      # @param [String] file_compression_format compression format of the application archive, e.g. 'zip' or 'tar.gz'
      # @return [void]
      def deploy(file, file_compression_format)
        extractor = Paasal::ArchiveExtractor.new
        fail Errors::AdapterRequestError,
             'Unsupported format of the application archive' unless extractor.supports? file_compression_format

        push_repository_changes do |repo_dir|
          # now remove all current files, except the git db
          Find.find(repo_dir) do |f|
            next if f.start_with?("#{repo_dir}/.git") || f == repo_dir
            FileUtils.remove_dir(f)
          end

          # uncompress and extract to
          extracted = extractor.extract(file, repo_dir, file_compression_format)
          fail Errors::AdapterRequestError, 'Invalid application: Archive did not contain any files' if extracted == 0

          # if the application was wrapped within a directory, move all 1st level files and dirs to the root
          sanitizer = Paasal::ApplicationRepoSanitizer.new
          sanitizer.sanitize(repo_dir)
        end
        nil
      end

      # Download the contents of a git repository in the requested format.
      # @param [String] format compression to be used for the download e.g. 'zip' or 'tar.gz'
      # @return [StringIO] data requested to be downloaded
      def download(format, exclude_git = true)
        with_repository do |repo_dir|
          # TODO: maybe we can do this directly via SSH and prevent the disk writes?
          # download files temporarily from the repo
          Paasal::Archiver.new(exclude_git).compress(repo_dir, format)
        end
      end

      private

      def with_repository
        tmp_dir = Dir.tmpdir
        repo_dir = "#{tmp_dir}/#{@repo_name}"
        begin
          repository = Git.clone(@repo_url, @repo_name, path: tmp_dir)
          # checkout custom branch
          unless @repo_branch == 'master'
            begin
              repository.checkout(repository.branch(@repo_branch))
            rescue StandardError => e
              # catch errors, might occur if no commit has been made and we try to switch the branch
              repository.checkout(@repo_branch, new_branch: true)
            end
          end

          # now execute the actual actions on the repository
          yield repo_dir, repository
        ensure
          # now delete the tmp directory again
          FileUtils.rm_rf(repo_dir)
        end
      end

      def push_repository_changes
        with_repository do |repo_dir, repository|
          repository.config('user.name', 'PaaSal')
          repository.config('user.email', @user_email)
          # update files
          yield repo_dir
          # push changes
          push(repository)
        end
      end

      # Push all contents of the repository to the default remote 'origin'.
      # The repository will also be pushed if none of the files did change and no new commit was made.
      # @param [Git::Lib] repository repository whose contents are to be pushed
      # @return [void]
      def push(repository)
        # add all files to the repository
        repository.add(all: true)

        # commit, but be aware: current version could be identical to previous version resulting in an error
        begin
          repository.commit('Application deployment via PaaSal')
        rescue Git::GitExecuteError => e
          # usually indicates that no files could be committed, repository is up to date
          log.debug("Git commit failed: #{e}")
        end

        # repack to enhance compression
        repository.repack

        # force push, so that the push is executed even when all files remain unchanged
        repository.push('origin', @repo_branch, force: true)
      end
    end
  end
end
