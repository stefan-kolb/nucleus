# set the temporary db file if is has not been specified via the config
unless paasal_config.db.key?(:path)
  puts 'No custom store specified, generating temporary store filename'
  paasal_config.db.path = "#{Dir.tmpdir}/#{SecureRandom.uuid}.paasal.store"
end

# Check the API versions once and make them available via configatron
paasal_config.api.versions = Paasal::ApiDetector.api_versions

# Add authorization strategy to grape and replace default http_basic
Grape::Middleware::Auth::Strategies.add(:http_basic, Paasal::Middleware::BasicAuth, ->(options) { [options[:realm]] })

# Now setup the SSH key that is required for Git deployment by (at least) Openshift
# first, load private key
keyfile = File.join('bin', 'paasal.pem')
paasal_config.public_key = SSHKey.new(File.read(keyfile), comment: 'PaaSal').ssh_public_key

if OS.unix?
  # file must not be accessible by others, otherwise usage will be forbidden by git
  FileUtils.chmod(0600, keyfile)
  tmp_ssh_script = File.join('bin', 'trust_unix_ssh')
  FileUtils.chmod('+x', tmp_ssh_script) unless File.executable?(tmp_ssh_script)
else
  tmp_ssh_script = File.join('bin', 'trust_win_ssh')
end

# use a custom SSH script
Git.configure { |config| config.git_ssh = tmp_ssh_script }

# Lock the configuration, so it can't be manipulated
paasal_config.lock!

puts "Rack environment: #{ENV['RACK_ENV']}" if ENV.key?('RACK_ENV')
puts 'Configuration locked!'
