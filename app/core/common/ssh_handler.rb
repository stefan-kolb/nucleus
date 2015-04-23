module Paasal
  class SSHHandler
    include Paasal::Logging

    attr_reader :location

    # Setup the SSHHandler.
    # @param [String] key_file path to the key file
    # @param [String] public_key full and valid ssh-rsa public key specification
    # @return [Paasal::SSHHandler] the created instance
    def initialize(key_file, public_key)
      # fail StandardError, 'Setup already performed' if @key_file || @public_key
      @key_file = key_file
      @public_key = public_key
      # use uuid so that more than 1 instance can run at the same time
      @location = File.expand_path(File.join(Dir.tmpdir, 'paasal_ssh_agent', SecureRandom.uuid))

      if OS.unix?
        # file must not be accessible by others, otherwise usage will be forbidden by git.
        # Currently we're doing it only for PaaSal's keyfile...
        FileUtils.chmod(0600, @key_file) unless paasal_config.ssh.key?(:custom_key)
      end

      # use a custom SSH script if not specified or explicitly requested
      Git.configure { |config| config.git_ssh = @location }
    end

    # Get the public key that shall be used for authentication.
    # Furthermore, the method assures that the agent, which was registered in the GIT_SSH variable, is available.
    # @return [String] ssh public key in full format (type, value, comment)
    def public_key
      return @public_key if File.exist?(@location)
      # create the agent if it does not exist (anymore)
      create_agent
      @public_key
    end

    private

    def create_agent
      log.debug('(Re-) creating the paasal ssh agent')
      # make sure path exists
      dirname = File.dirname(@location)
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

      if OS.unix?
        File.write(@location, "ssh -i #{@key_file} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $*")
        FileUtils.chmod(0700, @location)
      else
        File.write(@location, "@echo off\r\nssh -i #{@key_file} -o UserKnownHostsFile=NUL "\
          '-o StrictHostKeyChecking=no %*')
      end
    end
  end
end
