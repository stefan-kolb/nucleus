include Paasal::Logging

# Shutdown hook to cleanup
require_relative 'shutdown.rb'

begin
  require_relative 'initialize_core.rb'
  log.info "DB store assigned to #{configatron.db.path}"

  # load vendors and put them into the db stores
  Paasal::AdapterImporter.new.import

  configatron.api.versions.each do |api_version|
    puts '', "Bootstraping DAOs for API #{api_version}"
    # Bootstrap DAOs for each API version
    Paasal::DB::VendorDao.instance api_version
    Paasal::DB::ProviderDao.instance api_version
    Paasal::DB::EndpointDao.instance api_version
    Paasal::DB::AdapterDao.instance api_version
    Paasal::DB::CacheDao.instance api_version
  end

  puts 'Initialization complete & configuration locked!'
  puts '-----------------------------------------------'
rescue Paasal::StartupError => e
  log.error "Application startup failed (#{e.exit_code}), exit now"
  exit e.exit_code
end
