module Nucleus
  class SSHHandler
    include Nucleus::Logging

    attr_reader :key_file

    # Setup the SSHHandler.
    # @param [String] custom_ssh_key_file path to the key file
    # @return [Nucleus::SSHHandler] the created instance
    def initialize(custom_ssh_key_file = nil)
      @custom_ssh_key_file = custom_ssh_key_file
      @key_file = @custom_ssh_key_file
      @key_file_history = []
      @agent_file_history = []

      if custom_ssh_key_file
        # file must not be accessible by others, otherwise usage will be forbidden by git.
        FileUtils.chmod(0o600, custom_ssh_key_file) if OS.unix?
        cache_public_key
      end

      # create the initial agent / key combination
      create_agent_key_combo
    end

    # Get the public key that shall be used for authentication.
    # Furthermore, the method assures that the agent, which was registered in the GIT_SSH variable, is available.
    # @return [String] ssh public key in full format (type, value, comment)
    def public_key
      return @public_key if File.exist?(@agent_file) && File.exist?(@key_file)
      # create the agent and key if at least one file does not exist (anymore)
      create_agent_key_combo
      @public_key
    end

    # Cleanup all created tmp files. Usually to be invoked before shutdown.
    def cleanup
      @agent_file_history.each { |af| FileUtils.rm_f(af) }
      @key_file_history.each { |kf| FileUtils.rm_f(kf) }
    end

    private

    def create_agent_key_combo
      log.debug('(Re-) creating the nucleus ssh agent')

      # create a new private key
      create_private_key

      # save the agent file
      create_agent

      # add to history so that it will be cleaned up
      add_history_entry

      # finally apply the custom SSH script
      Git.configure { |config| config.git_ssh = @agent_file }
    end

    def create_private_key
      # only create a new tmp key if no custom key location was specified
      return if @custom_ssh_key_file

      log.debug('Create new private key file')
      @key_file = File.expand_path(File.join(Dir.tmpdir, 'nucleus', 'ssh', 'key', "#{SecureRandom.uuid}.pem"))
      # make sure key file path exists
      FileUtils.mkdir_p(File.dirname(@key_file))

      # generates default key of type RSA and with 2048 bits
      File.write(@key_file, SSHKey.generate(type: 'RSA', bits: 2048, comment: 'tmp_key_4_nucleus').private_key)
      cache_public_key

      # file must not be accessible by others, otherwise usage will be forbidden by git.
      FileUtils.chmod(0o600, @key_file) if OS.unix?
    end

    def create_agent
      # use uuid so that more than one instance can run at the same time
      @agent_file = File.expand_path(File.join(Dir.tmpdir, 'nucleus', 'ssh', 'agent', SecureRandom.uuid))
      # windows requires the extension, otherwise git complains that it can't spawn such a file
      @agent_file = "#{@agent_file}.bat" if OS.windows?
      # make sure agent file path exists
      FileUtils.mkdir_p(File.dirname(@agent_file))

      # adapt the agent file to OS specific requirements
      if OS.unix?
        File.write(@agent_file, "ssh -i #{@key_file} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $*")
        FileUtils.chmod(0o700, @agent_file)
      else
        File.write(@agent_file, "@echo off\r\nssh -i #{@key_file} -o UserKnownHostsFile=NUL "\
          '-o StrictHostKeyChecking=no %*')
      end
    end

    def add_history_entry
      @key_file_history.push(@key_file) unless @custom_ssh_key_file
      @agent_file_history.push(@agent_file)
    end

    def cache_public_key
      @public_key = SSHKey.new(File.read(@key_file), comment: 'Nucleus').ssh_public_key
    rescue StandardError
      msg = "Invalid custom SSH key '#{@key_file}', must be of type ssh-rsa."
      STDERR.puts msg
      raise Nucleus::StartupError.new(msg, Nucleus::ExitCodes::INVALID_SSH_KEY)
    end
  end
end
