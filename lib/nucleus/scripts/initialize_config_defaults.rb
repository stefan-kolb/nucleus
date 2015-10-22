# Check the API versions once and make them available via configatron
nucleus_config.api.versions = Nucleus::VersionDetector.api_versions

# make sure the key is always set
key_file = nil
if nucleus_config.ssh.key?(:custom_key) && !nucleus_config.ssh.custom_key.nil?
  puts "Loading custom SSH key #{nucleus_config.ssh.custom_key}"
  # use the custom key file
  key_file = nucleus_config.ssh.custom_key

  # fail if file does not exist
  unless File.exist?(key_file)
    msg = "Could not find the SSH key: '#{key_file}'"
    STDERR.puts msg
    fail Nucleus::StartupError.new(msg, Nucleus::ExitCodes::INVALID_SSH_KEY_FILE)
  end

  if File.read(key_file).include?('ENCRYPTED')
    msg = "Provided private key '#{key_file}' must not be protected with a passphrase."
    STDERR.puts msg
    fail Nucleus::StartupError.new(msg, Nucleus::ExitCodes::INVALID_SSH_KEY_FILE_PROTECTED)
  end
end

# now setup the SSHHandler
nucleus_config.ssh.handler = Nucleus::SSHHandler.new(key_file)
