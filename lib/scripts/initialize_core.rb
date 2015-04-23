# set the temporary db file if is has not been specified via the config
unless paasal_config.db.key?(:path)
  puts 'No custom store specified, generating temporary store filename'
  paasal_config.db.path = "#{Dir.tmpdir}/#{SecureRandom.uuid}.paasal.store"
end

# Check the API versions once and make them available via configatron
paasal_config.api.versions = Paasal::ApiDetector.api_versions

# Add authorization strategy to grape and replace default http_basic
Grape::Middleware::Auth::Strategies.add(:http_basic, Paasal::Middleware::BasicAuth, ->(options) { [options[:realm]] })

# make sure the key is always set
if paasal_config.ssh.key?(:custom_key) && !paasal_config.ssh.custom_key.nil?
  puts "Loading custom SSH key #{paasal_config.ssh.custom_key}"
  # use the custom key file
  keyfile = paasal_config.ssh.custom_key
else
  puts 'Loading default SSH key'
  # Now setup the SSH key that is required for Git deployment by (at least) Openshift
  # first, load private key
  keyfile = File.join('config', 'paasal_git_key.pem')
end

# fail if file does not exist
unless File.exist?(keyfile)
  msg = "Could not find the SSH key: '#{keyfile}'"
  STDERR.puts msg
  fail Paasal::StartupError.new(msg, Paasal::ExitCodes::INVALID_SSH_KEY_FILE)
end

if File.read(keyfile).include?('ENCRYPTED')
  msg = "Provided private key '#{keyfile}' must not be protected with a passphrase."
  STDERR.puts msg
  fail Paasal::StartupError.new(msg, Paasal::ExitCodes::INVALID_SSH_KEY_FILE_PROTECTED)
end

begin
  public_key = SSHKey.new(File.read(keyfile), comment: 'PaaSal').ssh_public_key
rescue
  msg = "Invalid SSH key '#{keyfile}', it key must be of type ssh-rsa."
  STDERR.puts msg
  raise Paasal::StartupError.new(msg, Paasal::ExitCodes::INVALID_SSH_KEY)
end

# now setup the SSHHandler
paasal_config.ssh.handler = Paasal::SSHHandler.new(keyfile, public_key)

# Lock the configuration, so it can't be manipulated
paasal_config.lock!

puts "Rack environment: #{ENV['RACK_ENV']}" if ENV.key?('RACK_ENV')
puts 'Configuration locked!'
