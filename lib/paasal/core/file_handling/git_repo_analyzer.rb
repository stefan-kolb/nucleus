module Paasal
  module Adapters
    module GitRepoAnalyzer
      # Is the repository having any branch?
      # @param [String] repo_host repository host where the repository can be retrieved
      # @param [String] repo_name name of the directory for the repository that shall be created in the tmp dir
      # @param [String] username user to authenticate with
      # @return [TrueClass, FalseClass] true if the repository has any non-empty branch, e.g. 'master'
      def self.any_branch?(repo_host, repo_name, username)
        detected_branch = false
        options = { forward_agent: true, auth_methods: ['publickey'],
                    keys: [nucleus_config.ssh.handler.key_file], keys_only: true }
        Net::SSH.start(repo_host, username, options) do |ssh|
          ssh.exec! "git-upload-pack '/#{repo_name}.git'" do |ch, stream, data|
            detected_branch = (detected_branch || data != '0000') unless stream == :stderr
            ch.close
          end
        end
        detected_branch
      end
    end
  end
end
