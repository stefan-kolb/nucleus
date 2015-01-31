include Paasal::Logging

# Shutdown hook to cleanup
require_relative 'shutdown.rb'

begin
  require_relative 'initialize_core.rb'
  log.info "DB store assigned to #{configatron.db.path}"

  # load vendors and put them into the db stores
  Paasal::AdapterImporter.new.import

  puts 'Initialization complete & configuration locked!'
  puts '-----------------------------------------------'

  # TODO: DEBUG CODE TO VISUALISE THE LOADED DB STATE

  configatron.api.versions.each do |api_version|
    puts '', "API #{api_version}:"
    vendor_dao = Paasal::DB::VendorDao.instance api_version
    provider_dao = Paasal::DB::ProviderDao.instance api_version
    endpoint_dao = Paasal::DB::EndpointDao.instance api_version

    vendor_dao.keys.each do |key|
      p vendor_dao.get key
    end
    provider_dao.keys.each do |key|
      p provider_dao.get key
    end
    endpoint_dao.keys.each do |key|
      p endpoint_dao.get key
    end
  end

rescue Paasal::StartupError => e
  log.error "Application startup failed (#{e.exit_code}), exit now"
  exit e.exit_code
end
