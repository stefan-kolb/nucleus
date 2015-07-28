# Check the API versions once and make them available via configatron
paasal_config.api.versions = Paasal::VersionDetector.api_versions

# make sure the key is always set
key_file = nil
if paasal_config.ssh.key?(:custom_key) && !paasal_config.ssh.custom_key.nil?
  puts "Loading custom SSH key #{paasal_config.ssh.custom_key}"
  # use the custom key file
  key_file = paasal_config.ssh.custom_key

  # fail if file does not exist
  unless File.exist?(key_file)
    msg = "Could not find the SSH key: '#{key_file}'"
    STDERR.puts msg
    fail Paasal::StartupError.new(msg, Paasal::ExitCodes::INVALID_SSH_KEY_FILE)
  end

  if File.read(key_file).include?('ENCRYPTED')
    msg = "Provided private key '#{key_file}' must not be protected with a passphrase."
    STDERR.puts msg
    fail Paasal::StartupError.new(msg, Paasal::ExitCodes::INVALID_SSH_KEY_FILE_PROTECTED)
  end
end

# now setup the SSHHandler
paasal_config.ssh.handler = Paasal::SSHHandler.new(key_file)