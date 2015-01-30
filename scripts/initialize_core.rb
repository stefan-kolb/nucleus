# set the temporary db file if is has not been specified via the config
unless configatron.db.key?(:path)
  puts 'No custom store specified, generating temporary store filename'
  configatron.db.path = "#{Dir.tmpdir}/#{SecureRandom.uuid}.paasal.store"
end

# Check the API versions once and make them available via configatron
api_detector = Paasal::ApiDetector.new
configatron.api.versions = api_detector.api_versions

# Add authorization strategy to grape and replace default http_basic
Grape::Middleware::Auth::Strategies.add(:http_basic, Paasal::Authenticator, ->(options) { [options[:realm]] })

# Lock the configuration, so it can't be manipulated
configatron.lock!
