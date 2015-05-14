module Paasal
  module Adapters
    module GitRepoAnalyzer
      # Is the repository having any branch?
      # @param [String] repo_host repository host where the repository can be retrieved
      # @param [String] repo_name name of the directory for the repository that shall be created in the tmp dir
      # @param [String] username user to authenticate with
      # @return [TrueClass, FalseClass] true if the repository has any non-empty branch, e.g. 'master'
      def self.any_branch?(repo_host, repo_name, username)
        repository_branches = nil
        Net::SSH.start(repo_host, username, forward_agent: true, auth_methods: ['publickey']) do |ssh|
          ssh.exec! "git-upload-pack '/#{repo_name}.git'" do |ch, stream, data|
            repository_branches = data unless stream == :stderr
            ch.close
          end
        end
        repository_branches != '0000'
      end
    end
  end
end
