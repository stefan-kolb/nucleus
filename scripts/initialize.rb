include Paasal::Logging

begin
  # set the temporary db file if is has not been specified via the config
  unless configatron.db.has_key?(:path)
    puts 'No custom store specified, generating temporary store filename'
    configatron.db.path = "#{Dir.tmpdir}/#{SecureRandom.uuid}.paasal.store"
  end
  log.info "DB store assigned to #{configatron.db.path}"

  # load vendors and put them into the db stores
  adapter_loader = Paasal::AdapterImporter.new
  adapter_loader.import_adapters

  # Check the API versions once and make them available via configatron
  api_detector = Paasal::ApiDetector.new
  configatron.api.versions = api_detector.get_api_versions

  # Lock the configuration, so it can't be manipulated
  configatron.lock!
  puts 'Initialization complete & configuration locked!'
  puts '-----------------------------------------------'

  # TODO DEBUG CODE TO VISUALISE THE LOADED DB STATE

  ['v1'].each do |api_version|
    puts '', "API #{api_version}:"
    vendor_dao = Paasal::DB::VendorDao.new api_version
    provider_dao = Paasal::DB::ProviderDao.new api_version
    endpoint_dao = Paasal::DB::EndpointDao.new api_version

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